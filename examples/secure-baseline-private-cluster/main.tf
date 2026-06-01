terraform {
  required_version = "~> 1.14"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.9"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.46.0, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azapi" {}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  name_prefix          = "aks-sbp-${substr(data.azapi_client_config.current.subscription_id, 0, 8)}"
  resource_group_id    = "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${local.resource_group_name}"
  resource_group_name  = "rg-${local.name_prefix}"
  selected_region      = "westeurope"
  subnet_agc_id        = "${local.virtual_network_id}/subnets/subnet-agc"
  subnet_aks_id        = "${local.virtual_network_id}/subnets/subnet-aks"
  subnet_api_server_id = "${local.virtual_network_id}/subnets/subnet-apiserver"
  virtual_network_id   = "${local.resource_group_id}/providers/Microsoft.Network/virtualNetworks/${local.virtual_network_name}"
  virtual_network_name = "vnet-${local.name_prefix}"
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

resource "azapi_resource" "resource_group" {
  location = local.selected_region
  name     = local.resource_group_name
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
}

resource "azapi_resource" "virtual_network" {
  location  = local.selected_region
  name      = local.virtual_network_name
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
      }
    }
  }
}

resource "azapi_resource" "subnet_aks" {
  name      = "subnet-aks"
  parent_id = local.virtual_network_id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "10.0.1.0/24"
    }
  }

  depends_on = [azapi_resource.virtual_network]
}

resource "azapi_resource" "subnet_agc" {
  name      = "subnet-agc"
  parent_id = local.virtual_network_id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "10.0.2.0/24"
      delegations = [{
        name = "agc-delegation"
        properties = {
          serviceName = "Microsoft.ServiceNetworking/trafficControllers"
        }
      }]
    }
  }
  retry = {
    error_message_regex  = ["InUseSubnetCannotBeDeleted"]
    interval_seconds     = 30
    max_interval_seconds = 120
  }

  depends_on = [azapi_resource.subnet_aks]
}

resource "azapi_resource" "subnet_api_server" {
  name      = "subnet-apiserver"
  parent_id = local.virtual_network_id
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  body = {
    properties = {
      addressPrefix = "10.0.3.0/28"
      delegations = [{
        name = "aks-delegation"
        properties = {
          serviceName = "Microsoft.ContainerService/managedClusters"
        }
      }]
    }
  }

  depends_on = [azapi_resource.subnet_agc]
}

resource "azapi_resource" "alb_identity" {
  location  = local.selected_region
  name      = "id-alb-controller"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
}

resource "azapi_resource" "aks_identity" {
  location  = local.selected_region
  name      = "id-aks-cluster"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
}

resource "random_uuid" "role_agc_config_manager" {}
resource "random_uuid" "role_alb_network_contributor" {}
resource "random_uuid" "role_aks_network_contributor" {}

data "azapi_client_config" "current" {}

resource "azapi_resource" "role_agc_config_manager" {
  name      = random_uuid.role_agc_config_manager.result
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.alb_identity.output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/fbc52c3f-28ad-4303-a892-8a056630b8f1"
    }
  }
  response_export_values = []
}

resource "azapi_resource" "role_alb_network_contributor" {
  name      = random_uuid.role_alb_network_contributor.result
  parent_id = local.subnet_agc_id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.alb_identity.output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7"
    }
  }
  response_export_values = []

  depends_on = [azapi_resource.subnet_agc]
}

resource "azapi_resource" "role_aks_network_contributor" {
  name      = random_uuid.role_aks_network_contributor.result
  parent_id = local.virtual_network_id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.aks_identity.output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7"
    }
  }
  response_export_values = []

  depends_on = [azapi_resource.virtual_network]
}

module "aks" {
  source = "../.."

  location  = local.selected_region
  name      = module.naming.kubernetes_cluster.name_unique
  parent_id = azapi_resource.resource_group.id
  api_server_access_profile = {
    enable_private_cluster  = true
    enable_vnet_integration = true
    subnet_id               = local.subnet_api_server_id
  }
  default_agent_pool = {
    vm_size             = "Standard_D2S_v6"
    os_sku              = "AzureLinux"
    vnet_subnet_id      = local.subnet_aks_id
    availability_zones  = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    count_of            = 1
    upgrade_settings = {
      max_surge = "10%"
    }
  }
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [azapi_resource.aks_identity.id]
  }
  network_profile = {
    network_plugin = "azure"
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
  }
  oidc_issuer_profile = {
    enabled = true
  }
  security_profile = {
    workload_identity = {
      enabled = true
    }
  }
  sku = {
    name = "Base"
    tier = "Standard"
  }

  depends_on = [
    azapi_resource.role_aks_network_contributor,
    azapi_resource.subnet_aks,
    azapi_resource.subnet_api_server,
  ]
}

resource "azapi_resource" "waf_policy" {
  location  = local.selected_region
  name      = "waf-agc-${module.naming.application_gateway.name_unique}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-05-01"
  body = {
    properties = {
      managedRules = {
        managedRuleSets = [{
          ruleSetType    = "Microsoft_DefaultRuleSet"
          ruleSetVersion = "2.1"
        }]
      }
      policySettings = {
        fileUploadLimitInMb    = 100
        maxRequestBodySizeInKb = 128
        mode                   = "Prevention"
        requestBodyCheck       = true
        state                  = "Enabled"
      }
    }
  }
}

module "application_gateway_for_containers" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-servicenetworking-trafficcontroller.git?ref=v1.0.1"

  location  = local.selected_region
  name      = "agc-${module.naming.application_gateway.name_unique}"
  parent_id = azapi_resource.resource_group.id
  associations = {
    main = {
      name               = "association-main"
      subnet_resource_id = local.subnet_agc_id
    }
  }
  frontends = {
    web = {
      name = "frontend-web"
    }
  }
  security_policies = {
    waf = {
      name                   = "secpol-waf"
      waf_policy_resource_id = azapi_resource.waf_policy.id
    }
  }

  depends_on = [
    azapi_resource.role_agc_config_manager,
    azapi_resource.role_alb_network_contributor,
    module.aks,
  ]
}
