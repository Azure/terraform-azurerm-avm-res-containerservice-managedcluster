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

locals {
  locations = [
    "eastus",
    "eastus2",
    "westus2",
    "centralus",
    "westeurope",
    "northeurope",
    "southeastasia",
    "japaneast",
  ]
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.locations) - 1
  min = 0
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

resource "azurerm_virtual_network" "vnet" {
  location            = azurerm_resource_group.this.location
  name                = "advanced-networking-vnet"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "default_subnet" {
  address_prefixes     = ["10.1.0.0/24"]
  name                 = "default"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "userpool_subnet" {
  address_prefixes     = ["10.1.1.0/24"]
  name                 = "userpool"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_user_assigned_identity" "identity" {
  location            = azurerm_resource_group.this.location
  name                = "aks-identity"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_user_assigned_identity" "kubelet_identity" {
  location            = azurerm_resource_group.this.location
  name                = "kubelet-identity"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "kubelet_role_assignment" {
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
  scope                = azurerm_user_assigned_identity.kubelet_identity.id
  role_definition_name = "Managed Identity Operator"
}

resource "azurerm_log_analytics_workspace" "workspace" {
  location            = azurerm_resource_group.this.location
  name                = "advanced-networking-log-analytics"
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

data "azurerm_client_config" "current" {}

# This example demonstrates using Advanced Networking with Cilium data plane
# for enhanced network observability and security features
module "advanced_networking" {
  source = "../.."

  default_node_pool = {
    name                         = "default"
    vm_size                      = "Standard_DS2_v2"
    vnet_subnet_id               = azurerm_subnet.default_subnet.id
    auto_scaling_enabled         = true
    max_count                    = 4
    max_pods                     = 30
    min_count                    = 2
    only_critical_addons_enabled = true
    upgrade_settings = {
      max_surge = "10%"
    }
  }
  location            = azurerm_resource_group.this.location
  name                = module.naming.kubernetes_cluster.name_unique
  resource_group_name = azurerm_resource_group.this.name
  # Enable Advanced Networking with observability and security features
  advanced_networking = {
    enabled = true
    observability = {
      enabled = true
    }
    security = {
      enabled = true
    }
  }
  automatic_upgrade_channel = "stable"
  azure_active_directory_role_based_access_control = {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }
  defender_log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
  dns_prefix                          = "advnetexample"
  kubelet_identity = {
    client_id                 = azurerm_user_assigned_identity.kubelet_identity.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet_identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet_identity.id
  }
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
  # Advanced Networking requires Azure CNI with Cilium data plane
  network_profile = {
    network_plugin      = "azure"
    network_data_plane  = "cilium"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
  }
  node_os_channel_upgrade = "Unmanaged"
  node_pools = {
    userpool = {
      name                 = "userpool"
      vm_size              = "Standard_DS2_v2"
      max_count            = 4
      max_pods             = 30
      min_count            = 2
      os_disk_size_gb      = 128
      vnet_subnet_id       = azurerm_subnet.userpool_subnet.id
      auto_scaling_enabled = true
      upgrade_settings = {
        max_surge = "10%"
      }
    }
  }
  oidc_issuer_enabled = true
  oms_agent = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
  }
  storage_profile = {
    blob_driver_enabled         = true
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }
  workload_identity_enabled = true

  depends_on = [azurerm_role_assignment.kubelet_role_assignment]
}
