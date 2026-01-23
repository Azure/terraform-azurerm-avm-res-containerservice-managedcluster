terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.46.0, < 5.0.0"
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


module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.10.0"

  is_recommended = true
}

# This allows us to randomize the region for the resource group.
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
  version = "0.4.2"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = local.location
  name     = module.naming.resource_group.name_unique
}

data "azurerm_client_config" "current" {}

module "create_before_destroy" {
  source = "../.."

  location  = azurerm_resource_group.this.location
  name      = module.naming.kubernetes_cluster.name_unique
  parent_id = azurerm_resource_group.this.id
  aad_profile = {
    enable_azure_rbac      = true
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = []
    managed                = true
  }
  agent_pools = {
    unp1 = {
      name                = "unp1"
      vm_size             = "Standard_D2S_v6"
      enable_auto_scaling = true
      max_count           = 2
      max_pods            = 30
      min_count           = 1
      os_disk_size_gb     = 128
      upgrade_settings = {
        max_surge = "10%"
      }
    }
    unp2 = {
      name                = "unp2"
      vm_size             = "Standard_DS2_v2"
      enable_auto_scaling = true
      max_count           = 2
      max_pods            = 30
      min_count           = 1
      os_disk_size_gb     = 128
      upgrade_settings = {
        max_surge = "10%"
      }
    }
  }
  create_agentpools_before_destroy = true
  default_agent_pool = {
    name                = "default"
    vm_size             = "Standard_DS2_v2"
    enable_auto_scaling = true
    max_count           = 2
    max_pods            = 30
    min_count           = 1
    mode                = "System"
    node_taints         = ["CriticalAddonsOnly=true:NoSchedule"]

    upgrade_settings = {
      max_surge = "10%"
    }
  }
  dns_prefix = "createexample"
  managed_identities = {
    system_assigned = true
  }
  network_profile = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
  }
}
