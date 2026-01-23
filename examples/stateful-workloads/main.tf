terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.46.0, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
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
  version = "0.4.2"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.11.0"

  is_recommended         = true
  region_name_regex      = "euap"
  region_name_regex_mode = "not_match"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

locals {
  location = module.regions.regions[random_integer.region_index.result].name
}

# Creating the resource group
######################################################################################################################
resource "azurerm_resource_group" "this" {
  location = coalesce(var.location, local.location)
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

module "stateful_workloads" {
  source = "../.."

  location  = azurerm_resource_group.this.location
  name      = coalesce(var.cluster_name, module.naming.kubernetes_cluster.name_unique)
  parent_id = azurerm_resource_group.this.id
  addon_profile_key_vault_secrets_provider = {
    enabled = true
    config = {
      enable_secret_rotation = true
    }
  }
  agent_pools = var.agent_pools
  auto_upgrade_profile = {
    upgrade_channel         = "stable"
    node_os_upgrade_channel = "NodeImage"
  }
  default_agent_pool = {
    name     = "systempool"
    count_of = 2
    vm_size  = "Standard_D2ds_v4"
    os_type  = "Linux"
    # Provide zones as strings for consistency with variable type list(string)
    availability_zones = ["2", "3"]

    upgrade_settings = {
      max_surge = "10%"
    }
  }
  disable_local_accounts = false
  dns_prefix             = "statefulworkloads"
  managed_identities = {
    system_assigned = true
  }
  network_profile = {
    network_plugin = "azure"
  }
  oidc_issuer_profile = {
    enabled = true
  }
  security_profile = {
    workload_identity = {
      enabled = true
    }
  }
  sku = {
    name = "Base"
    tier = "Standard"
  }
}

## Section to assign the role to the kubelet identity
######################################################################################################################
resource "azurerm_role_assignment" "acr_role_assignment" {
  principal_id         = module.stateful_workloads.kubelet_identity.objectId
  scope                = module.avm_res_containerregistry_registry.resource_id
  role_definition_name = "AcrPull"

  depends_on = [module.avm_res_containerregistry_registry, module.stateful_workloads]
}

## Section to deploy valkey cluster only when var.valkey_enabled is set to true
######################################################################################################################
module "valkey" {
  source = "./valkey"
  count  = var.valkey_enabled ? 1 : 0

  key_vault_id    = module.avm_res_keyvault_vault.resource_id
  object_id       = module.stateful_workloads.key_vault_secrets_provider_identity.objectId
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
  oidc_issuer_url      = module.stateful_workloads.oidc_issuer_profile_issuer_url
  principal_id         = data.azurerm_client_config.current.object_id
  resource_group_name  = azurerm_resource_group.this.name
  service_account_name = var.service_account_name
  storage_account_name = coalesce(var.aks_mongodb_backup_storage_account_name, module.naming.storage_account.name_unique)
}
