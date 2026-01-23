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

resource "azurerm_virtual_network" "vnet" {
  location            = azurerm_resource_group.this.location
  name                = "private-vnet"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "api_server" {
  address_prefixes     = ["10.1.0.0/28"]
  name                 = "apiServerSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  lifecycle {
    ignore_changes = [delegation]
  }
}

resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.1.1.0/24"]
  name                 = "default"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "unp1_subnet" {
  address_prefixes     = ["10.1.2.0/24"]
  name                 = "unp1"
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

resource "azurerm_role_assignment" "private_dns_zone_contributor" {
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
  scope                = azurerm_private_dns_zone.zone.id
  role_definition_name = "Private DNS Zone Contributor"
}

resource "azurerm_role_assignment" "network_contributor" {
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
}

resource "random_string" "dns_prefix" {
  length  = 10    # Set the length of the string
  lower   = true  # Use lowercase letters
  numeric = true  # Include numbers
  special = false # No special characters
  upper   = false # No uppercase letters
}

data "azurerm_client_config" "current" {}

module "private" {
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
      name                = "userpool1"
      vm_size             = "Standard_D2S_v6"
      mode                = "User"
      type                = "VirtualMachineScaleSets"
      enable_auto_scaling = true
      max_count           = 4
      max_pods            = 30
      min_count           = 2
      os_disk_size_gb     = 128
      vnet_subnet_id      = azurerm_subnet.unp1_subnet.id
      upgrade_settings = {
        max_surge = "10%"
      }
    }
  }
  agentpool_timeouts = {
    create = "20m"
    delete = "20m"
    read   = "5m"
    update = "20m"
  }
  api_server_access_profile = {
    enable_private_cluster = true
    private_dns_zone       = azurerm_private_dns_zone.zone.id
  }
  default_agent_pool = {
    name                = "default"
    vm_size             = "Standard_D2S_v6"
    enable_auto_scaling = true
    max_count           = 4
    max_pods            = 30
    min_count           = 2
    vnet_subnet_id      = azurerm_subnet.subnet.id
    node_taints         = ["CriticalAddonsOnly=true:NoSchedule"]

    upgrade_settings = {
      max_surge = "10%"
    }
  }
  fqdn_subdomain = random_string.dns_prefix.result
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [azurerm_user_assigned_identity.identity.id]
  }
  network_profile = {
    # In enterprise environments you typically want to manage outbound traffic using your own routing.
    # This reuqires user defined routing (UDR) to be setup in the subnet used by the AKS cluster.
    # outbound_type       = "userDefinedRouting"
    dns_service_ip      = "10.10.200.10"
    service_cidr        = "10.10.200.0/24"
    pod_cidr            = "100.64.0.0/10"
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    advanced_networking = {
      enabled = true
      observability = {
        enabled = true
      }
    }
  }
  sku = {
    name = "Base"
    tier = "Standard"
  }

  depends_on = [
    azurerm_role_assignment.private_dns_zone_contributor,
    azurerm_role_assignment.network_contributor,
  ]
}
