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

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

data "azurerm_client_config" "current" {}

# This is the module call with cluster extensions
module "cluster_with_extensions" {
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
  addon_profile_oms_agent = {
    enabled = true
    config = {
      log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.this.id
      use_aad_auth                        = true
    }
  }
  auto_upgrade_profile = {
    upgrade_channel = "none"
  }
  # Cluster Extensions Configuration
  cluster_extension = {
    dapr = {
      name              = "dapr"
      extension_type    = "Microsoft.Dapr"
      version           = "1.14.4-msft.10"
      release_namespace = "dapr-system"
      configuration_settings = {
        "global.mtoDefaultNamespace" = "default"
      }
    }
    flux = {
      name              = "flux"
      extension_type    = "Microsoft.Flux"
      release_namespace = "flux-system"
      configuration_settings = {
        "helm.repositories.url" = "https://fluxcd-community.github.io/helm-charts"
      }
    }
  }
  default_agent_pool = {
    vm_size = "standard_a2_v2"

    upgrade_settings = {
      max_surge = "10%"
    }
  }
  diagnostic_settings = {
    to_la = {
      name                  = "to-la"
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
    }
  }
  dns_prefix = "extexample"
  managed_identities = {
    system_assigned = true
  }
  sku = {
    tier = "Standard"
    name = "Base"
  }
}
