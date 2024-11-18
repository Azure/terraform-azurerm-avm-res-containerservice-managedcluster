terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "< 4.0.0"
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


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

data "azurerm_client_config" "current" {}

module "create_before_destroy" {
  source                          = "../.."
  name                            = module.naming.kubernetes_cluster.name_unique
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  create_nodepools_before_destroy = true

  azure_active_directory_role_based_access_control = {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  default_node_pool = {
    name                         = "default"
    vm_size                      = "Standard_DS2_v2"
    auto_scaling_enabled         = true
    max_count                    = 3
    max_pods                     = 30
    min_count                    = 1
    only_critical_addons_enabled = true

    upgrade_settings = {
      max_surge = "10%"
    }
  }

  network_profile = {
    network_plugin = "kubenet"
  }

  node_pools = {
    unp1 = {
      name                 = "unp1"
      vm_size              = "Standard_DS2_v2"
      zones                = [3]
      auto_scaling_enabled = true
      max_count            = 3
      max_pods             = 30
      min_count            = 1
      os_disk_size_gb      = 128
      upgrade_settings = {
        max_surge = "10%"
      }
    }
    unp2 = {
      name                 = "unp2"
      vm_size              = "Standard_DS2_v2"
      zones                = [3]
      auto_scaling_enabled = true
      max_count            = 3
      max_pods             = 30
      min_count            = 1
      os_disk_size_gb      = 128
      upgrade_settings = {
        max_surge = "10%"
      }
    }
  }
}
