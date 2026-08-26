terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azapi" {}

# This ensures we have unique CAF compliant names for our resources.
######################################################################################################################

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

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

# Section to get the current client config
######################################################################################################################

data "azapi_client_config" "current" {}

# Creating the resource group
######################################################################################################################
resource "azapi_resource" "rg" {
  location               = coalesce(var.location, local.location)
  name                   = coalesce(var.resource_group_name, module.naming.resource_group.name_unique)
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  response_export_values = []
}

# Section to Create the Azure Key Vault
######################################################################################################################

resource "azapi_resource" "key_vault" {
  location  = azapi_resource.rg.location
  name      = coalesce(var.keyvault_name, module.naming.key_vault.name_unique)
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.KeyVault/vaults@2023-07-01"
  body = {
    properties = {
      accessPolicies            = []
      enableRbacAuthorization   = true
      enableSoftDelete          = true
      publicNetworkAccess       = "Enabled"
      softDeleteRetentionInDays = 7
      tenantId                  = data.azapi_client_config.current.tenant_id
      sku = {
        family = "A"
        name   = "standard"
      }
    }
  }
  response_export_values = ["properties.vaultUri"]
}

## Section to let the deploying principal write the workload secrets held in the key vault
######################################################################################################################

# Role assignment resource names must be GUIDs.
resource "random_uuid" "key_vault_administrator" {}

# principalType is omitted because the caller can be either a user or a service principal.
resource "azapi_resource" "role_key_vault_administrator" {
  name      = random_uuid.key_vault_administrator.result
  parent_id = azapi_resource.key_vault.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = data.azapi_client_config.current.object_id
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483"
    }
  }
  response_export_values = []
}

## Section to create the Azure Container Registry
######################################################################################################################
resource "azapi_resource" "acr" {
  location  = azapi_resource.rg.location
  name      = coalesce(var.acr_registry_name, module.naming.container_registry.name_unique)
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.ContainerRegistry/registries@2023-07-01"
  body = {
    sku = {
      name = "Premium"
    }
    properties = {
      adminUserEnabled         = false
      networkRuleBypassOptions = "AzureServices"
      publicNetworkAccess      = "Enabled"
    }
  }
  response_export_values = []
}

## Section to create the Azure Kubernetes Service
######################################################################################################################

module "stateful_workloads" {
  source = "../.."

  location  = azapi_resource.rg.location
  name      = coalesce(var.cluster_name, module.naming.kubernetes_cluster.name_unique)
  parent_id = azapi_resource.rg.id
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
    vm_size  = "Standard_DC2ds_v3"
    os_type  = "Linux"

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
resource "random_uuid" "acr_pull" {}

resource "azapi_resource" "role_acr_pull" {
  name      = random_uuid.acr_pull.result
  parent_id = azapi_resource.acr.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = module.stateful_workloads.kubelet_identity.objectId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d"
    }
  }
  response_export_values = []
  # The kubelet identity may not have replicated to Entra ID yet.
  retry = {
    error_message_regex  = ["PrincipalNotFound", "does not exist in the directory"]
    interval_seconds     = 10
    max_interval_seconds = 60
  }
}
