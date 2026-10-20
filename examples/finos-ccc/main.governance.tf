# CCC.K8S.CN04.AR01: the approved, private container registry. Nodes pull through a
# private endpoint with the kubelet identity; anonymous and admin access stay disabled.
module "container_registry" {
  source    = "Azure/avm-res-containerregistry-registry/azurerm"
  version   = "0.8.0"
  providers = { modtm = modtm }

  location            = var.location
  name                = "acrccc${random_string.name_suffix.result}"
  resource_group_name = local.resource_group_name
  enable_telemetry    = var.enable_telemetry
  private_endpoints = {
    cluster = {
      name                          = "pe-ccc-acr-${random_string.name_suffix.result}"
      subnet_resource_id            = local.container_registry_private_endpoint_subnet_id
      private_dns_zone_resource_ids = [local.container_registry_private_dns_zone_id]
    }
  }
  public_network_access_enabled = false
  role_assignments = {
    kubelet_acr_pull = {
      role_definition_id_or_name       = "AcrPull"
      principal_id                     = local.kubelet_principal_id
      principal_type                   = "ServicePrincipal"
      skip_service_principal_aad_check = true
    }
  }
  sku                     = "Premium"
  tags                    = var.tags
  zone_redundancy_enabled = true
}

module "container_registry_dns_zone" {
  source    = "Azure/avm-res-network-privatednszone/azurerm"
  version   = "0.5.0"
  providers = { modtm = modtm }
  count     = var.container_registry_private_dns_zone_id == null ? 1 : 0

  domain_name      = "privatelink.azurecr.io"
  parent_id        = local.resource_group_id
  enable_telemetry = var.enable_telemetry
  tags             = var.tags
  virtual_network_links = {
    cluster = {
      name                 = "cluster-vnet"
      virtual_network_id   = local.virtual_network_id
      registration_enabled = false
      tags                 = var.tags
    }
  }
}

# Azure Policy for Kubernetes assignments, scoped to this cluster only.
# CCC.K8S.CN11.AR01: every non-system namespace is governed by deny-mode admission policy.
# No AVM resource module exists for policy assignments; the AVM pattern module is used.

# CCC.K8S.CN05.AR01/AR02: Kubernetes restricted pod security standard.
module "policy_restricted_pod_security" {
  source  = "Azure/avm-ptn-policyassignment/azurerm"
  version = "0.2.2"

  location             = var.location
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/42b8ef37-b724-4e24-bbc8-7a7708edfe00"
  scope                = module.aks.resource_id
  display_name         = "CCC.K8S.CN05: restricted pod security standard"
  enable_telemetry     = var.enable_telemetry
  name                 = "ccc-k8s-cn05-restricted"
  # CN05.AR02: no capabilities may be added back and every container must drop ALL.
  parameters = {
    effect                   = { value = "Deny" }
    allowedCapabilities      = { value = [] }
    requiredDropCapabilities = { value = ["ALL"] }
  }
}

# CCC.K8S.CN04.AR01: images must come from the approved registry and be pinned by digest.
module "policy_allowed_images" {
  source  = "Azure/avm-ptn-policyassignment/azurerm"
  version = "0.2.2"

  location             = var.location
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/febd0533-8e55-448f-b837-bd0e06f16469"
  scope                = module.aks.resource_id
  display_name         = "CCC.K8S.CN04: approved registry and immutable digest"
  enable_telemetry     = var.enable_telemetry
  name                 = "ccc-k8s-cn04-allowed-images"
  parameters = {
    effect                      = { value = "Deny" }
    allowedContainerImagesRegex = { value = "^${module.container_registry.name}\\.azurecr\\.io/.+@sha256:[a-f0-9]{64}$" }
  }
}

# CCC.K8S.CN13.AR01: every container declares CPU and memory limits within approved bounds.
module "policy_resource_limits" {
  source  = "Azure/avm-ptn-policyassignment/azurerm"
  version = "0.2.2"

  location             = var.location
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e345eecc-fa47-480f-9e88-67dcc122b164"
  scope                = module.aks.resource_id
  display_name         = "CCC.K8S.CN13: container CPU and memory limits"
  enable_telemetry     = var.enable_telemetry
  name                 = "ccc-k8s-cn13-resource-limits"
  parameters = {
    effect      = { value = "Deny" }
    cpuLimit    = { value = var.container_cpu_limit }
    memoryLimit = { value = var.container_memory_limit }
  }
}
