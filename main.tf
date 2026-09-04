resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  # applicationLoadBalancer requires the 2025-09-02-preview API. kubeProxyConfig is not available in the stable 2026-03-01 API.
  type                 = try(var.ingress_profile.application_load_balancer, null) != null ? "Microsoft.ContainerService/managedClusters@2025-09-02-preview" : var.kube_proxy_config == null ? var.resource_types.containerservice_managed_clusters : "Microsoft.ContainerService/managedClusters@2026-03-02-preview"
  body                 = local.resource_body
  ignore_body_changes  = length(var.ignore_body_changes.containerservice_managed_clusters) > 0 ? var.ignore_body_changes.containerservice_managed_clusters : null
  ignore_null_property = true
  replace_triggers_refs = [
    "properties.nodeResourceGroup",
    "properties.agentPoolProfiles[0].vnetSubnetID",
  ]
  response_export_values = [
    "properties.addonProfiles.ingressApplicationGateway.identity",
    "properties.addonProfiles.azureKeyvaultSecretsProvider",
    "properties.currentKubernetesVersion",
    "properties.fqdn",
    "properties.identityProfile.kubeletidentity",
    "properties.ingressProfile.applicationLoadBalancer.identity",
    "properties.ingressProfile.webAppRouting.identity",
    "properties.maxAgentPools",
    "properties.networkProfile.loadBalancerProfile.effectiveOutboundIPs",
    "properties.networkProfile.natGatewayProfile.effectiveOutboundIPs",
    "properties.nodeResourceGroup",
    "properties.oidcIssuerProfile.issuerURL",
    "properties.privateFQDN",
  ]
  retry = var.retry
  # AzAPI's embedded AKS schema does not include 2026-03-01 yet.
  # Azure still validates the request at apply time.
  schema_validation_enabled = false
  sensitive_body            = local.sensitive_body
  sensitive_body_version = var.windows_profile == null ? null : {
    "properties.windowsProfile.adminPassword" = var.windows_profile_password_version
  }
  tags = var.tags

  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  dynamic "timeouts" {
    for_each = local.effective_timeouts == null ? [] : [local.effective_timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    ignore_changes = [
      body.properties.agentPoolProfiles,
      body.properties.kubernetesVersion,
    ]
  }
}

resource "azapi_update_resource" "kubernetes_version" {
  count = var.kubernetes_version == null ? 0 : 1

  name      = var.name
  parent_id = var.parent_id
  type      = azapi_resource.this.type
  body = {
    properties = {
      kubernetesVersion = var.kubernetes_version
    }
  }
  locks = [
    azapi_resource.this.id,
  ]
  response_export_values = []
}

resource "random_string" "dns_prefix" {
  length  = 10
  lower   = true
  numeric = true
  special = false
  upper   = false
}

moved {
  from = azurerm_kubernetes_cluster.this
  to   = azapi_resource.this
}

# required AVM resource interfaces
resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(module.interfaces.lock_azapi.name, "lock-${var.lock.kind}")
  parent_id = azapi_resource.this.id
  type      = module.interfaces.lock_azapi.type
  body = merge(module.interfaces.lock_azapi.body, {
    properties = merge(module.interfaces.lock_azapi.body.properties, {
      notes = coalesce(
        var.lock.notes,
        var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
      )
    })
  })
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = local.effective_timeouts == null ? [] : [local.effective_timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [
    azapi_resource.diagnostic_settings,
    azapi_resource.private_dns_zone_groups,
    azapi_resource.role_assignments,
  ]
}

resource "azapi_resource" "role_assignments" {
  for_each = module.interfaces.role_assignments_azapi

  name                   = each.value.name
  parent_id              = azapi_resource.this.id
  type                   = each.value.type
  body                   = each.value.body
  ignore_null_property   = true
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = local.effective_timeouts == null ? [] : [local.effective_timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource_action" "this_user_kubeconfig" {
  count = local.is_automatic ? 0 : 1

  action                 = "listClusterUserCredential"
  method                 = "POST"
  resource_id            = azapi_resource.this.id
  type                   = azapi_resource.this.type
  response_export_values = ["kubeconfigs"]
}

resource "azapi_resource_action" "this_admin_kubeconfig" {
  count = local.is_automatic || var.disable_local_accounts ? 0 : 1

  action                 = "listClusterAdminCredential"
  method                 = "POST"
  resource_id            = azapi_resource.this.id
  type                   = azapi_resource.this.type
  response_export_values = ["kubeconfigs"]
}

locals {
  kubeconfig_admin = length(azapi_resource_action.this_admin_kubeconfig) == 1 ? base64decode(azapi_resource_action.this_admin_kubeconfig[0].output.kubeconfigs[0].value) : null
  kubeconfig_user  = !local.is_automatic ? base64decode(azapi_resource_action.this_user_kubeconfig[0].output.kubeconfigs[0].value) : null
}
