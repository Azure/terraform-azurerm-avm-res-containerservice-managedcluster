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

module "regions" {
  source         = "Azure/avm-utl-regions/azurerm"
  version        = "0.9.0"
  is_recommended = true
  region_filter  = ["swedencentral"]
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

  location                   = azurerm_resource_group.this.location
  name                       = module.naming.kubernetes_cluster.name_unique
  parent_id                  = azurerm_resource_group.this.id
  alert_email                = "test@example.com"
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
  onboard_alerts          = true
  onboard_monitoring      = true
  prometheus_workspace_id = azurerm_monitor_workspace.example.id
  sku = {
    name = "Automatic"
    tier = "Standard"
  }
}
