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

# Ensure to select a region that meets criteria for AKS Automatic clusters.
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

resource "azapi_resource" "monitor_workspace" {
  location  = azapi_resource.this.location
  name      = "prom-${random_string.suffix.result}"
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Monitor/accounts@2023-04-03"
  body = {
    properties = {}
  }
  response_export_values = []
}

resource "azapi_resource" "virtual_network" {
  location  = azapi_resource.this.location
  name      = module.naming.virtual_network.name_unique
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["172.19.0.0/16"]
      }
    }
  }
  response_export_values = []
}

resource "azapi_resource" "public_ip_nat_gateway" {
  location  = azapi_resource.this.location
  name      = "pip-nat-${random_string.suffix.result}"
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Network/publicIPAddresses@2024-05-01"
  body = {
    sku = {
      name = "Standard"
      tier = "Regional"
    }
    zones = ["1", "2", "3"]
    properties = {
      publicIPAllocationMethod = "Static"
      publicIPAddressVersion   = "IPv4"
    }
  }
  response_export_values = []
}

resource "azapi_resource" "nat_gateway" {
  location  = azapi_resource.this.location
  name      = "nat-${random_string.suffix.result}"
  parent_id = azapi_resource.this.id
  type      = "Microsoft.Network/natGateways@2024-05-01"
  body = {
    sku = {
      name = "Standard"
    }
    properties = {
      idleTimeoutInMinutes = 4
      publicIpAddresses = [{
        id = azapi_resource.public_ip_nat_gateway.id
      }]
    }
  }
  response_export_values = []
}

# Subnets are written serially against the shared parent virtual network to
# avoid concurrent-write conflicts on the VNet resource.
resource "azapi_resource" "subnet_api_server" {
  name      = "apiServerSubnet"
  parent_id = azapi_resource.virtual_network.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "172.19.0.0/28"
    }
  }
  response_export_values = []

  lifecycle {
    ignore_changes = [body.properties.delegations]
  }
}

resource "azapi_resource" "subnet_cluster" {
  name      = "clusterSubnet"
  parent_id = azapi_resource.virtual_network.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "172.19.1.0/24"
      natGateway = {
        id = azapi_resource.nat_gateway.id
      }
    }
  }
  response_export_values = []

  depends_on = [azapi_resource.subnet_api_server]
}

resource "azapi_resource" "subnet_system" {
  name      = "systemSubnet"
  parent_id = azapi_resource.virtual_network.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "172.19.2.0/24"
      natGateway = {
        id = azapi_resource.nat_gateway.id
      }
    }
  }
  response_export_values = []

  lifecycle {
    ignore_changes = [body.properties.delegations]
  }
  depends_on = [azapi_resource.subnet_cluster]
}

resource "azapi_resource" "user_assigned_identity" {
  location               = azapi_resource.this.location
  name                   = module.naming.user_assigned_identity.name_unique
  parent_id              = azapi_resource.this.id
  type                   = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  response_export_values = ["properties.principalId"]
}

resource "random_uuid" "network_contributor" {}

resource "azapi_resource" "network_contributor" {
  name      = random_uuid.network_contributor.result
  parent_id = azapi_resource.virtual_network.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.user_assigned_identity.output.properties.principalId
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

resource "azapi_resource" "private_dns_zone_virtual_network_link" {
  location  = "global"
  name      = "privatelink-${azapi_resource.this.location}-azmk8s-io"
  parent_id = azapi_resource.private_dns_zone.id
  type      = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01"
  body = {
    properties = {
      registrationEnabled = false
      virtualNetwork = {
        id = azapi_resource.virtual_network.id
      }
    }
  }
  response_export_values = []
}

resource "random_uuid" "private_dns_zone_contributor" {}

resource "azapi_resource" "private_dns_zone_contributor" {
  name      = random_uuid.private_dns_zone_contributor.result
  parent_id = azapi_resource.private_dns_zone.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.user_assigned_identity.output.properties.principalId
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

resource "azapi_resource" "log_analytics_workspace" {
  location  = azapi_resource.this.location
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

module "automatic" {
  source = "../.."

  location  = azapi_resource.this.location
  name      = module.naming.kubernetes_cluster.name_unique
  parent_id = azapi_resource.this.id
  addon_profile_oms_agent = {
    enabled = true
    config = {
      log_analytics_workspace_resource_id = azapi_resource.log_analytics_workspace.id
      use_aad_auth                        = true
    }
  }
  alert_email = "test@this.com"
  api_server_access_profile = {
    subnet_id              = azapi_resource.subnet_api_server.id
    enable_private_cluster = true
    private_dns_zone       = azapi_resource.private_dns_zone.id
    disable_run_command    = true
  }
  default_agent_pool = {
    vnet_subnet_id = azapi_resource.subnet_cluster.id
  }
  hosted_system_profile = {
    enabled               = true
    node_subnet_id        = azapi_resource.subnet_cluster.id
    system_node_subnet_id = azapi_resource.subnet_system.id
  }
  ingress_profile = {
    gateway_api = {
      installation = "Disabled"
    }
    web_app_routing = {
      enabled = true
      gateway_api_implementations = {
        app_routing_istio = {
          mode = "Disabled"
        }
      }
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
    user_assigned_resource_ids = [azapi_resource.user_assigned_identity.id]
  }
  network_profile = {
    outbound_type = "userAssignedNATGateway"
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

  depends_on = [
    azapi_resource.nat_gateway,
    azapi_resource.network_contributor,
    azapi_resource.subnet_cluster,
    azapi_resource.subnet_system,
  ]
}
