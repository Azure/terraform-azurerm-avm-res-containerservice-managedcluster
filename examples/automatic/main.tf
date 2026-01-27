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

data "azurerm_client_config" "current" {}

# Ensure to select a region that meets criteria for AKS Automatic clusters.
# See this doc for more info: https://learn.microsoft.com/azure/aks/automatic/quick-automatic-managed-network?pivots=azure-portal#limitations
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.10.0"

  is_recommended = true
  region_filter  = ["swedencentral"]
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
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

resource "azurerm_monitor_workspace" "example" {
  location            = azurerm_resource_group.this.location
  name                = "prom-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

module "automatic" {
  source = "../.."

  location  = azurerm_resource_group.this.location
  name      = module.naming.kubernetes_cluster.name_unique
  parent_id = azurerm_resource_group.this.id
  addon_profile_oms_agent = {
    enabled = true
    config = {
      log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.this.id
      use_aad_auth                        = true
    }
  }
  alert_email = "test@example.com"
  maintenanceconfiguration = {
    aksManagedAutoUpgradeSchedule = {
      name = "aksManagedAutoUpgradeSchedule"
      maintenance_window = {
        duration_hours = 4
        start_time     = "00:00"
        utc_offset     = "+00:00"
        start_date     = "2025-09-27"
        schedule = {
          weekly = {
            day_of_week    = "Sunday"
            interval_weeks = 1
          }
        }
      }
    }
  }
  onboard_alerts          = true
  onboard_monitoring      = true
  prometheus_workspace_id = azurerm_monitor_workspace.example.id
  role_assignments = {
    "admin" = {
      principal_id               = data.azurerm_client_config.current.object_id
      role_definition_id_or_name = "Azure Kubernetes Service RBAC Admin"
    }
  }
  sku = {
    name = "Automatic"
    tier = "Standard"
  }
}
