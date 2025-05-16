terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# This ensures we have unique CAF compliant names for our resources.
######################################################################################################################

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# Creating the resource group
######################################################################################################################
resource "azurerm_resource_group" "this" {
  location = coalesce(var.location, "eastus")
  name     = coalesce(var.resource_group_name, module.naming.resource_group.name_unique)
}


# Section to get the current client config
######################################################################################################################

data "azurerm_client_config" "current" {}


# Section to Create the Azure Key Vault 
######################################################################################################################

module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.9.1"

  location            = azurerm_resource_group.this.location
  name                = coalesce(var.keyvault_name, module.naming.key_vault.name_unique)
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  legacy_access_policies = {
    permissions = {
      object_id          = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "Set", "List"]
    }
  }
  legacy_access_policies_enabled = true
  network_acls                   = null
  public_network_access_enabled  = true
}

# ## Section to create the Azure Container Registry
# ######################################################################################################################
module "avm_res_containerregistry_registry" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.4.0"

  location            = azurerm_resource_group.this.location
  name                = coalesce(var.acr_registry_name, module.naming.container_registry.name_unique)
  resource_group_name = azurerm_resource_group.this.name
  admin_enabled       = false
  sku                 = "Premium"
}

## Section to create the Azure Container Registry task
######################################################################################################################
resource "azurerm_container_registry_task" "this" {
  container_registry_id = module.avm_res_containerregistry_registry.resource_id
  name                  = "image-import-task"

  encoded_step {
    task_content = base64encode(var.acr_task_content)
  }
  identity {
    type = "SystemAssigned" # Note this has to be a System Assigned Identity to work with private networking and `network_rule_bypass_option` set to `AzureServices`
  }
  platform {
    os = "Linux"
  }

  depends_on = [module.avm_res_containerregistry_registry]
}


## Section to assign the role to the task identity
######################################################################################################################
resource "azurerm_role_assignment" "container_registry_import_for_task" {
  principal_id         = azurerm_container_registry_task.this.identity[0].principal_id
  scope                = module.avm_res_containerregistry_registry.resource_id
  role_definition_name = "Container Registry Data Importer and Data Reader"
}

## Section to run the Azure Container Registry task
######################################################################################################################
resource "azurerm_container_registry_task_schedule_run_now" "this" {
  container_registry_task_id = azurerm_container_registry_task.this.id

  depends_on = [azurerm_role_assignment.container_registry_import_for_task]

  lifecycle {
    replace_triggered_by = [azurerm_container_registry_task.this]
  }
}

## Section to create the Azure Kubernetes Service
######################################################################################################################
module "default" {
  source = "../.."

  default_node_pool = {
    name                    = "systempool"
    node_count              = 3
    vm_size                 = "Standard_D2ds_v4"
    os_type                 = "Linux"
    auto_upgrade_channel    = "stable"
    node_os_upgrade_channel = "NodeImage"
    zones                   = [2, 3]

    addon_profile = {
      azure_key_vault_secrets_provider = {
        enabled = true
      }
    }
    upgrade_settings = {
      max_surge = "10%"
    }
  }
  location                  = azurerm_resource_group.this.location
  name                      = coalesce(var.cluster_name, module.naming.kubernetes_cluster.name_unique)
  resource_group_name       = azurerm_resource_group.this.name
  automatic_upgrade_channel = "stable"
  key_vault_secrets_provider = {
    secret_rotation_enabled = true
  }
  local_account_disabled = false
  managed_identities = {
    system_assigned = true
  }
  network_profile = {
    network_plugin = "azure"
  }
  node_os_channel_upgrade   = "NodeImage"
  node_pools                = var.node_pools
  oidc_issuer_enabled       = true
  sku_tier                  = "Standard"
  workload_identity_enabled = true
}

## Section to assign the role to the kubelet identity
######################################################################################################################
resource "azurerm_role_assignment" "acr_role_assignment" {
  principal_id         = module.default.kubelet_identity_id
  scope                = module.avm_res_containerregistry_registry.resource_id
  role_definition_name = "AcrPull"

  depends_on = [module.avm_res_containerregistry_registry, module.default]
}

## Section to deploy valkey cluster only when var.valkey_enabled is set to true
######################################################################################################################
module "valkey" {
  source = "./valkey"
  count  = var.valkey_enabled ? 1 : 0

  key_vault_id    = module.avm_res_keyvault_vault.resource_id
  object_id       = module.default.key_vault_secrets_provider_object_id
  tenant_id       = data.azurerm_client_config.current.tenant_id
  valkey_password = var.valkey_password
}

## Section to deploy MongoDB cluster only when var.mongodb_enabled is set to true
######################################################################################################################
module "mongodb" {
  source = "./mongodb"
  count  = var.mongodb_enabled ? 1 : 0

  identity_name        = coalesce(var.identity_name, module.naming.user_assigned_identity.name_unique)
  key_vault_id         = module.avm_res_keyvault_vault.resource_id
  location             = azurerm_resource_group.this.location
  mongodb_kv_secrets   = var.mongodb_kv_secrets
  mongodb_namespace    = var.mongodb_namespace
  oidc_issuer_url      = module.default.oidc_issuer_url
  principal_id         = data.azurerm_client_config.current.object_id
  resource_group_name  = azurerm_resource_group.this.name
  service_account_name = var.service_account_name
  storage_account_name = coalesce(var.aks_mongodb_backup_storage_account_name, module.naming.storage_account.name_unique)
}
