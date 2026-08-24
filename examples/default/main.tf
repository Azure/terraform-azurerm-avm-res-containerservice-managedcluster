terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azapi" {}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

  region_filter = ["northeurope"]
}

# This selects a known-good region for AKS and Log Analytics example testing.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

locals {
  location = module.regions.regions[random_integer.region_index.result].name
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

data "azapi_client_config" "current" {}

# This is required for resource modules
resource "azapi_resource" "resource_group" {
  location               = local.location
  name                   = module.naming.resource_group.name_unique
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  response_export_values = []
}

resource "azapi_resource" "log_analytics_workspace" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.log_analytics_workspace.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.OperationalInsights/workspaces@2023-09-01"
  body = {
    properties = {
      retentionInDays = 30
      sku = {
        name = "PerGB2018"
      }
    }
  }
  response_export_values = []
}

# This is the module call.
# Use the resource group location selected above so the module and prerequisites deploy together.
module "default" {
  source = "../.."

  location  = azapi_resource.resource_group.location
  name      = module.naming.kubernetes_cluster.name_unique
  parent_id = azapi_resource.resource_group.id
  aad_profile = {
    enable_azure_rbac      = true
    tenant_id              = data.azapi_client_config.current.tenant_id
    admin_group_object_ids = []
    managed                = true
  }
  addon_profile_oms_agent = {
    enabled = true
    config = {
      log_analytics_workspace_resource_id = azapi_resource.log_analytics_workspace.id
      use_aad_auth                        = true
    }
  }
  auto_upgrade_profile = {
    upgrade_channel = "none"
  }
  default_agent_pool = {
    count_of = 1
    vm_size  = "Standard_B2s_v2"

    upgrade_settings = {
      max_surge = "10%"
    }
  }
  diagnostic_settings = {
    to_la = {
      name                  = "to-la"
      workspace_resource_id = azapi_resource.log_analytics_workspace.id
    }
  }
  dns_prefix = "defaultexample"
  managed_identities = {
    system_assigned = true
  }
  sku = {
    tier = "Standard"
    name = "Base"
  }
}
