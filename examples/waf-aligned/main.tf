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

data "azapi_client_config" "current" {}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

  has_availability_zones = true
  is_recommended         = true
  region_name_regex      = "euap"
  region_name_regex_mode = "not_match"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

## End of section to provide a random Azure region for the resource group

locals {
  location = module.regions.regions[random_integer.region_index.result].name
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

resource "azapi_resource" "this" {
  location               = local.location
  name                   = module.naming.resource_group.name_unique
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  response_export_values = []
}

resource "azapi_resource" "vnet" {
  location  = azapi_resource.this.location
  name      = "waf-vnet"
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.1.0.0/16"]
      }
    }
  }
  response_export_values = []
}

# Subnets are chained so writes to the parent virtual network happen serially.
resource "azapi_resource" "subnet_api_server" {
  name      = "apiServerSubnet"
  parent_id = azapi_resource.vnet.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "10.1.0.0/28"
      delegations = [{
        name = "aks-delegation"
        properties = {
          serviceName = "Microsoft.ContainerService/managedClusters"
        }
      }]
    }
  }
  response_export_values = []
}

resource "azapi_resource" "subnet_default" {
  name      = "default"
  parent_id = azapi_resource.vnet.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "10.1.1.0/24"
    }
  }
  response_export_values = []

  depends_on = [azapi_resource.subnet_api_server]
}

resource "azapi_resource" "subnet_unp1" {
  name      = "unp1"
  parent_id = azapi_resource.vnet.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "10.1.2.0/24"
    }
  }
  response_export_values = []

  depends_on = [azapi_resource.subnet_default]
}

resource "azapi_resource" "private_dns_zone" {
  location  = "global"
  name      = "privatelink.${azapi_resource.this.location}.azmk8s.io"
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Network/privateDnsZones@2024-06-01"
  body = {
    properties = {}
  }
  response_export_values = []
}

# Identity for the managed cluster
resource "azapi_resource" "identity" {
  location               = azapi_resource.this.location
  name                   = "aks-identity"
  parent_id              = azapi_resource.this.id
  type                   = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  response_export_values = ["properties.principalId"]
}

# Identity for the kubelet, used to pull images from ACR for example
resource "azapi_resource" "kubelet_identity" {
  location               = azapi_resource.this.location
  name                   = "aks-kubelet-identity"
  parent_id              = azapi_resource.this.id
  type                   = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  response_export_values = ["properties.principalId"]
}

# Role assignment resource names must be GUIDs.
resource "random_uuid" "managed_identity_operator" {}

resource "random_uuid" "network_contributor" {}

resource "random_uuid" "private_dns_zone_contributor" {}

resource "azapi_resource" "role_managed_identity_operator" {
  name      = random_uuid.managed_identity_operator.result
  parent_id = azapi_resource.kubelet_identity.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.identity.output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/f1a07417-d97a-45cb-824c-7a7467783830"
    }
  }
  response_export_values = []
  # The user-assigned identity may not have replicated to Entra ID yet.
  retry = {
    error_message_regex  = ["PrincipalNotFound", "does not exist in the directory"]
    interval_seconds     = 10
    max_interval_seconds = 60
  }
}

resource "azapi_resource" "role_network_contributor" {
  name      = random_uuid.network_contributor.result
  parent_id = azapi_resource.vnet.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.identity.output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7"
    }
  }
  response_export_values = []
  # The user-assigned identity may not have replicated to Entra ID yet.
  retry = {
    error_message_regex  = ["PrincipalNotFound", "does not exist in the directory"]
    interval_seconds     = 10
    max_interval_seconds = 60
  }
}

resource "azapi_resource" "role_private_dns_zone_contributor" {
  name      = random_uuid.private_dns_zone_contributor.result
  parent_id = azapi_resource.private_dns_zone.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.identity.output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/b12aa53e-6015-4669-85d0-8515ebb3ae7f"
    }
  }
  response_export_values = []
  # The user-assigned identity may not have replicated to Entra ID yet.
  retry = {
    error_message_regex  = ["PrincipalNotFound", "does not exist in the directory"]
    interval_seconds     = 10
    max_interval_seconds = 60
  }
}

resource "azapi_resource" "private_dns_zone_vnet_link" {
  location  = "global"
  name      = "privatelink-${azapi_resource.this.location}-azmk8s-io"
  parent_id = azapi_resource.private_dns_zone.id
  type      = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01"
  body = {
    properties = {
      registrationEnabled = false
      virtualNetwork = {
        id = azapi_resource.vnet.id
      }
    }
  }
  response_export_values = []
}

resource "azapi_resource" "log_analytics_workspace" {
  location  = azapi_resource.this.location
  name      = "waf-log-analytics"
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

resource "random_string" "dns_prefix" {
  length  = 10    # Set the length of the string
  lower   = true  # Use lowercase letters
  numeric = true  # Include numbers
  special = false # No special characters
  upper   = false # No uppercase letters
}

module "waf_aligned" {
  source = "../.."

  location  = azapi_resource.this.location
  name      = module.naming.kubernetes_cluster.name_unique
  parent_id = azapi_resource.this.id
  aad_profile = {
    tenant_id              = data.azapi_client_config.current.tenant_id
    enable_azure_rbac      = true
    admin_group_object_ids = []
    managed                = true
  }
  addon_profile_oms_agent = {
    enabled = true
    config = {
      log_analytics_workspace_resource_id = azapi_resource.log_analytics_workspace.id
      use_aad_auth                        = true
    }
  }
  agent_pools = {
    unp1 = {
      name                = "userpool1"
      vm_size             = "Standard_D2S_v6"
      enable_auto_scaling = true
      max_count           = 3
      max_pods            = 50
      min_count           = 2
      os_disk_size_gb     = 60
      vnet_subnet_id      = azapi_resource.subnet_unp1.id

      upgrade_settings = {
        max_surge = "10%"
      }
    }
  }
  api_server_access_profile = {
    enable_private_cluster  = true
    enable_vnet_integration = true
    private_dns_zone        = azapi_resource.private_dns_zone.id
    subnet_id               = azapi_resource.subnet_api_server.id
  }
  auto_scaler_profile = {
    expander                   = "random"
    scan_interval              = "20s"
    scale_down_unneeded_time   = "10m"
    scale_down_delay_after_add = "10m"
  }
  auto_upgrade_profile = {
    upgrade_channel         = "stable"
    node_os_upgrade_channel = "Unmanaged"
  }
  default_agent_pool = {
    name                = "default"
    vm_size             = "Standard_D2S_v6"
    enable_auto_scaling = true
    max_count           = 5
    max_pods            = 50
    min_count           = 2
    vnet_subnet_id      = azapi_resource.subnet_default.id
    mode                = "System"
    node_taints         = ["CriticalAddonsOnly=true:NoSchedule"]
    upgrade_settings = {
      max_surge = "10%"
    }
  }
  disable_local_accounts = true
  fqdn_subdomain         = random_string.dns_prefix.result
  identity_profile = {
    kubeletidentity = {
      resource_id = azapi_resource.kubelet_identity.id
    }
  }
  maintenanceconfiguration = {
    aksManagedAutoUpgradeSchedule = {
      name = "aksManagedAutoUpgradeSchedule"
      maintenance_window = {
        duration_hours = 4
        start_time     = "00:00"
        utc_offset     = "+00:00"
        start_date     = "2024-10-15"
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
    system_assigned            = false
    user_assigned_resource_ids = [azapi_resource.identity.id]
  }
  network_profile = {
    # In enterprise environments you typically want to manage outbound traffic using your own routing.
    # This reuqires user defined routing (UDR) to be setup in the subnet used by the AKS cluster.
    # outbound_type       = "userDefinedRouting"
    dns_service_ip      = "10.10.200.10"
    service_cidr        = "10.10.200.0/24"
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_dataplane   = "cilium"
    advanced_networking = {
      enabled = true
      observability = {
        enabled = true
      }
      security = {
        enabled                   = true
        advanced_network_policies = "FQDN"
      }
    }
  }
  role_assignments = {
    rbac_admin = {
      principal_id                     = data.azapi_client_config.current.object_id
      role_definition_id_or_name       = "Azure Kubernetes Service RBAC Cluster Admin"
      skip_service_principal_aad_check = false
    }
  }
  security_profile = {
    defender = {
      log_analytics_workspace_resource_id = azapi_resource.log_analytics_workspace.id
      security_monitoring = {
        enabled = true
      }
    }
  }
  sku = {
    name = "Base"
    tier = "Standard"
  }

  depends_on = [
    azapi_resource.role_private_dns_zone_contributor,
    azapi_resource.role_network_contributor,
    azapi_resource.role_managed_identity_operator,
  ]
}
