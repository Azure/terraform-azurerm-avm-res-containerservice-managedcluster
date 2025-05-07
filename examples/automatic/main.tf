terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
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


locals {
  locations = [
    "eastus",
    "eastus2",
    "westus2",
    "centralus",
    "westeurope",
    "northeurope",
    "southeastasia",
    "japaneast",
  ]
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.locations) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

locals {
  location = local.locations[random_integer.region_index.result]
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = local.location
  name     = module.naming.resource_group.name_unique
}

data "azurerm_client_config" "current" {}

module "automatic" {
  source = "../.."

  default_node_pool = {
    name       = "default"
    vm_size    = "Standard_DS2_v2"
    node_count = 3
    upgrade_settings = {
      max_surge = "10%"
    }
  }
  location            = azurerm_resource_group.this.location
  name                = module.naming.kubernetes_cluster.name_unique
  resource_group_name = azurerm_resource_group.this.name
  azure_active_directory_role_based_access_control = {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }
  maintenance_window_auto_upgrade = {
    frequency   = "Weekly"
    interval    = "1"
    day_of_week = "Sunday"
    duration    = 4
    utc_offset  = "+00:00"
    start_time  = "00:00"
    start_date  = "2024-10-15T00:00:00Z"
  }
  managed_identities = {
    system_assigned = true
  }
}
