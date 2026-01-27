terraform {
  required_version = ">= 1.9, < 2.0"

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

resource "azurerm_monitor_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = "prom-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_virtual_network" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["172.19.0.0/16"]
}

resource "azurerm_subnet" "api_server" {
  address_prefixes     = ["172.19.0.0/28"]
  name                 = "apiServerSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name

  lifecycle {
    ignore_changes = [delegation]
  }
}

resource "azurerm_subnet" "cluster" {
  address_prefixes     = ["172.19.1.0/24"]
  name                 = "clusterSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "network_contributor" {
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  scope                = azurerm_virtual_network.this.id
  role_definition_name = "Network Contributor"
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.${azurerm_resource_group.this.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "privatelink-${azurerm_resource_group.this.location}-azmk8s-io"
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.this.id
}

resource "azurerm_role_assignment" "private_dns_zone_contributor" {
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  scope                = azurerm_private_dns_zone.this.id
  role_definition_name = "Private DNS Zone Contributor"
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
  alert_email = "test@this.com"
  api_server_access_profile = {
    subnet_id              = azurerm_subnet.api_server.id
    enable_private_cluster = true
    private_dns_zone       = azurerm_private_dns_zone.this.id
    disable_run_command    = true
  }
  default_agent_pool = {
    vnet_subnet_id = azurerm_subnet.cluster.id
  }
  ingress_profile = {
    web_app_routing = {
      enabled = true
      nginx = {
        default_ingress_controller_type = "Internal"
      }
    }
  }
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
  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
  }
  network_profile = {
    # Change this to userDefinedRouting to prevent creation of public IP.
    outbound_type = "loadBalancer"
  }
  onboard_alerts          = true
  onboard_monitoring      = true
  prometheus_workspace_id = azurerm_monitor_workspace.this.id
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

  depends_on = [
    azurerm_role_assignment.network_contributor
  ]
}
