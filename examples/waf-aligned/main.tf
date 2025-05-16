terraform {
  required_version = ">= 1.9.2"
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

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "eastus"
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = "waf-vnet"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.1.0.0/24"]
  name                 = "default"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "unp1" {
  address_prefixes     = ["10.1.1.0/24"]
  name                 = "unp1"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "unp2" {
  address_prefixes     = ["10.1.2.0/24"]
  name                 = "unp2"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_private_dns_zone" "zone" {
  name                = "privatelink.${azurerm_resource_group.this.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_user_assigned_identity" "identity" {
  location            = azurerm_resource_group.this.location
  name                = "aks-identity"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "private_dns_zone_contributor" {
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
  scope                = azurerm_private_dns_zone.zone.id
  role_definition_name = "Private DNS Zone Contributor"
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "privatelink-${azurerm_resource_group.this.location}-azmk8s-io"
  private_dns_zone_name = azurerm_private_dns_zone.zone.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_log_analytics_workspace" "workspace" {
  location            = azurerm_resource_group.this.location
  name                = "waf-log-analytics"
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

resource "random_string" "dns_prefix" {
  length  = 10    # Set the length of the string
  lower   = true  # Use lowercase letters
  numeric = true  # Include numbers
  special = false # No special characters
  upper   = false # No uppercase letters
}

data "azurerm_client_config" "current" {}

module "waf_aligned" {
  source = "../.."

  default_node_pool = {
    name                         = "default"
    vm_size                      = "Standard_DS2_v2"
    node_count                   = 3
    zones                        = [2, 3]
    auto_scaling_enabled         = true
    max_count                    = 3
    max_pods                     = 50
    min_count                    = 3
    vnet_subnet_id               = azurerm_subnet.subnet.id
    only_critical_addons_enabled = true

    upgrade_settings = {
      max_surge = "10%"
    }
  }
  location                  = azurerm_resource_group.this.location
  name                      = module.naming.kubernetes_cluster.name_unique
  resource_group_name       = azurerm_resource_group.this.name
  automatic_upgrade_channel = "stable"
  azure_active_directory_role_based_access_control = {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled = true
  }
  defender_log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
  dns_prefix_private_cluster          = random_string.dns_prefix.result
  maintenance_window_auto_upgrade = {
    frequency   = "Weekly"
    interval    = "1"
    day_of_week = "Sunday"
    duration    = 4
    utc_offset  = "+00:00"
    start_time  = "00:00"
    start_date  = "2024-10-15T00:00:00Z"
  }
  maintenance_window_node_os = {
    frequency   = "Weekly"
    interval    = "1"
    day_of_week = "Sunday"
    duration    = 4
    utc_offset  = "+00:00"
    start_time  = "00:00"
    start_date  = "2024-10-15T00:00:00Z"
  }
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [azurerm_user_assigned_identity.identity.id]
  }
  network_profile = {
    dns_service_ip = "10.10.200.10"
    service_cidr   = "10.10.200.0/24"
    network_plugin = "azure"
  }
  node_os_channel_upgrade = "Unmanaged"
  node_pools = {
    unp1 = {
      name                 = "userpool1"
      vm_size              = "Standard_DS2_v2"
      zones                = [3]
      auto_scaling_enabled = true
      max_count            = 3
      max_pods             = 50
      min_count            = 3
      os_disk_size_gb      = 60
      vnet_subnet_id       = azurerm_subnet.unp1.id

      upgrade_settings = {
        max_surge = "10%"
      }
    }
    unp2 = {
      name                 = "userpool2"
      vm_size              = "Standard_DS2_v2"
      node_count           = 3
      zones                = [3]
      auto_scaling_enabled = true
      max_count            = 3
      max_pods             = 50
      min_count            = 3
      os_disk_size_gb      = 60
      vnet_subnet_id       = azurerm_subnet.unp2.id
      upgrade_settings = {
        max_surge = "10%"
      }
    }
  }
  oms_agent = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
  }
  private_cluster_enabled = true
  private_dns_zone_id     = azurerm_private_dns_zone.zone.id
  sku_tier                = "Standard"

  depends_on = [azurerm_role_assignment.private_dns_zone_contributor]
}
