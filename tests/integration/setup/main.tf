terraform {
  required_version = ">= 1.9, < 2.0"

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

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.11.0"

  is_recommended         = true
  region_name_regex      = "euap"
  region_name_regex_mode = "not_match"
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

data "azapi_client_config" "current" {}

resource "azapi_resource" "resource_group" {
  location  = module.regions.regions[random_integer.region_index.result].name
  name      = module.naming.resource_group.name_unique
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
}

output "resource_group_id" {
  value = azapi_resource.resource_group.id
}

output "resource_group_location" {
  value = azapi_resource.resource_group.location
}

output "cluster_name" {
  value = module.naming.kubernetes_cluster.name_unique
}
