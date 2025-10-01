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

# AKS Automatic requires API Server VNet Integration which is not available in all regions yet.
# See for updated locations: https://learn.microsoft.com/azure/aks/api-server-vnet-integration
locals {
  locations = [
    "australiacentral",
    "australiacentral2",
    "australiaeast",
    "australiasoutheast",
    "austriaeast",
    "brazilsouth",
    "brazilsoutheast",
    "canadacentral",
    "canadaeast",
    "centralindia",
    "centralus",
    "centraluseuap",
    "chilecentral",
    "eastasia",
    "eastus",
    "francecentral",
    "francesouth",
    "germanynorth",
    "germanywestcentral",
    "indonesiacentral",
    "israelcentral",
    "israelnorthwest",
    "italynorth",
    "japaneast",
    "japanwest",
    "jioindiacentral",
    "jioindiawest",
    "koreacentral",
    "koreasouth",
    "malaysiawest",
    "mexicocentral",
    "newzealandnorth",
    "northcentralus",
    "northeurope",
    "norwayeast",
    "norwaywest",
    "polandcentral",
    "southafricanorth",
    "southafricawest",
    "southcentralus",
    "southcentralus2",
    "southeastasia",
    "southeastus",
    "southeastus3",
    "southeastus5",
    "southindia",
    "southwestus",
    "spaincentral",
    "swedencentral",
    "swedensouth",
    "switzerlandnorth",
    "switzerlandwest",
    "taiwannorth",
    "taiwannorthwest",
    "uaecentral",
    "uaenorth",
    "uksouth",
    "ukwest",
    "usgovtexas",
    "westcentralus",
    "westeurope",
    "westus",
    "westus2",
    "westus3"
  ]
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.locations) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  location = local.locations[random_integer.region_index.result]
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

  location            = azurerm_resource_group.this.location
  name                = module.naming.kubernetes_cluster.name_unique
  resource_group_name = azurerm_resource_group.this.name
  alert_email         = "test@this.com"
  api_server_access_profile = {
    vnet_subnet_id = azurerm_subnet.api_server.id
  }
  default_node_pool = {
    vnet_subnet_id = azurerm_subnet.cluster.id
  }
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  maintenance_window_auto_upgrade = {
    frequency   = "Weekly"
    interval    = 1
    day_of_week = "Sunday"
    duration    = 4
    utc_offset  = "+00:00"
    start_time  = "00:00"
    start_date  = "2025-09-27"
  }
  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
  }
  monitor_workspace_id = azurerm_monitor_workspace.this.id
  network_profile = {
    outbound_type = "loadBalancer"
  }
  onboard_alerts          = true
  onboard_monitoring      = true
  private_cluster_enabled = true
  private_dns_zone_id     = azurerm_private_dns_zone.this.id
  sku = {
    name = "Automatic"
    tier = "Standard"
  }

  depends_on = [
    azurerm_role_assignment.network_contributor
  ]
}
