<!-- BEGIN_TF_DOCS -->
# Private Cluster example

This deploys the module in Private Cluster mode.

```hcl
terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0"
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

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = "private-vnet"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.1.0.0/24"]
  name                 = "default"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "unp1_subnet" {
  address_prefixes     = ["10.1.1.0/24"]
  name                 = "unp1"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "unp2_subnet" {
  address_prefixes     = ["10.1.2.0/24"]
  name                 = "unp2"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_private_dns_zone" "zone" {
  name                = "privatelink.${azurerm_resource_group.this.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "privatelink-${azurerm_resource_group.this.location}-azmk8s-io"
  private_dns_zone_name = azurerm_private_dns_zone.zone.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_user_assigned_identity" "identity" {
  location            = azurerm_resource_group.this.location
  name                = "aks-identity"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "privateDNSZoneContributor" {
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
  scope                = azurerm_private_dns_zone.zone.id
  role_definition_name = "Private DNS Zone Contributor"
}

resource "random_string" "dns_prefix" {
  length  = 10    # Set the length of the string
  lower   = true  # Use lowercase letters
  numeric = true  # Include numbers
  special = false # No special characters
  upper   = false # No uppercase letters
}

module "private" {
  source     = "../.."
  depends_on = [azurerm_role_assignment.privateDNSZoneContributor]

  name                       = module.naming.kubernetes_cluster.name_unique
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  sku_tier                   = "Standard"
  private_cluster_enabled    = true
  private_dns_zone_id        = azurerm_private_dns_zone.zone.id
  dns_prefix_private_cluster = random_string.dns_prefix.result

  identity = {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity.id]
  }
  network_profile = {
    dns_service_ip = "10.10.200.10"
    service_cidr   = "10.10.200.0/24"
    network_plugin = "azure"
  }
  default_node_pool = {
    name                         = "default"
    vm_size                      = "Standard_DS2_v2"
    node_count                   = 1
    zones                        = [3]
    auto_scaling_enabled         = true
    max_count                    = 3
    max_pods                     = 30
    min_count                    = 1
    vnet_subnet_id               = azurerm_subnet.subnet.id
    only_critical_addons_enabled = true

    upgrade_settings = {
      max_surge = "10%"
    }
  }

  node_pools = [
    {
      name                 = "userpool1"
      vm_size              = "Standard_DS2_v2"
      node_count           = 2
      zones                = [3]
      auto_scaling_enabled = true
      max_count            = 3
      max_pods             = 30
      min_count            = 1
      os_disk_size_gb      = 128
      vnet_subnet_id       = azurerm_subnet.unp1_subnet.id

      upgrade_settings = {
        max_surge = "10%"
      }
    },
    {
      name                 = "userpool2"
      vm_size              = "Standard_DS2_v2"
      node_count           = 2
      zones                = [3]
      auto_scaling_enabled = true
      max_count            = 3
      max_pods             = 30
      min_count            = 1
      os_disk_size_gb      = 128
      vnet_subnet_id       = azurerm_subnet.unp2_subnet.id

      upgrade_settings = {
        max_surge = "10%"
      }
    }
  ]

}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9.2)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.116.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_private_dns_zone.zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone_virtual_network_link.vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.privateDNSZoneContributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.unp1_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet.unp2_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_user_assigned_identity.identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_string.dns_prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

### <a name="module_private"></a> [private](#module\_private)

Source: ../..

Version:

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: ~> 0.1

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->