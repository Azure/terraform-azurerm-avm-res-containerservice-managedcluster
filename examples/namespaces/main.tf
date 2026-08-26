terraform {
  required_version = "~> 1.11"

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

data "azapi_client_config" "current" {}

# Ensure to select a region that supports AKS Automatic clusters.
# See this doc for more info: https://learn.microsoft.com/azure/aks/automatic/quick-automatic-managed-network?pivots=azure-portal#limitations
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

  is_recommended = true
  region_filter  = ["swedencentral"]
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

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
  version = "0.4.3"
}

# This is required for resource modules
resource "azapi_resource" "this" {
  location               = local.location
  name                   = module.naming.resource_group.name_unique
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  response_export_values = []
}

resource "azapi_resource" "log_analytics_workspace" {
  location  = local.location
  name      = module.naming.log_analytics_workspace.name_unique
  parent_id = azapi_resource.this.id
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

resource "azapi_resource" "monitor_workspace" {
  location  = local.location
  name      = "prom-${random_string.suffix.result}"
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Monitor/accounts@2023-04-03"
  body = {
    properties = {}
  }
  response_export_values = []
}

module "namespaces" {
  source = "../.."

  location  = local.location
  name      = module.naming.kubernetes_cluster.name_unique
  parent_id = azapi_resource.this.id
  addon_profile_oms_agent = {
    enabled = true
    config = {
      log_analytics_workspace_resource_id = azapi_resource.log_analytics_workspace.id
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
  namespace = {
    app1 = {
      name = "app1"
      annotations = {
        "example.com/owner" = "team-platform"
      }
      labels = {
        environment = "dev"
      }
      default_network_policy = {
        ingress = "AllowSameNamespace"
        egress  = "AllowAll"
      }
      default_resource_quota = {
        cpu_limit      = "2000m"
        cpu_request    = "500m"
        memory_limit   = "4Gi"
        memory_request = "1Gi"
      }
      adoption_policy = "IfIdentical"
      delete_policy   = "Delete"
    }
    app2 = {
      name = "app2"
      labels = {
        environment = "dev"
      }
      default_network_policy = {
        ingress = "AllowSameNamespace"
        egress  = "AllowAll"
      }
      default_resource_quota = {
        cpu_limit      = "1000m"
        cpu_request    = "250m"
        memory_limit   = "2Gi"
        memory_request = "512Mi"
      }
      adoption_policy = "Never"
      delete_policy   = "Keep"
    }
  }
  onboard_alerts          = true
  onboard_monitoring      = true
  prometheus_workspace_id = azapi_resource.monitor_workspace.id
  role_assignments = {
    "admin" = {
      principal_id               = data.azapi_client_config.current.object_id
      role_definition_id_or_name = "Azure Kubernetes Service RBAC Admin"
    }
  }
  sku = {
    name = "Automatic"
    tier = "Standard"
  }
}
