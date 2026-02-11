resource "azapi_resource" "this" {
  location             = var.location
  name                 = var.name
  parent_id            = var.parent_id
  type                 = "Microsoft.ContainerService/managedClusters@2025-10-01"
  body                 = local.resource_body
  create_headers       = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers       = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_null_property = true
  read_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_refs = [
    "properties.nodeResourceGroup",
    "properties.agentPoolProfiles[0].vnetSubnetID",
  ]
  response_export_values = [
    "properties.currentKubernetesVersion",
    "properties.fqdn",
    "properties.identityProfile.kubeletidentity",
    "properties.ingressProfile.webAppRouting.identity",
    "properties.maxAgentPools",
    "properties.networkProfile.loadBalancerProfile.effectiveOutboundIPs",
    "properties.networkProfile.natGatewayProfile.effectiveOutboundIPs",
    "properties.nodeResourceGroup",
    "properties.oidcIssuerProfile.issuerURL",
    "properties.privateFQDN",
  ]
  sensitive_body = local.sensitive_body
  sensitive_body_version = var.windows_profile == null ? null : {
    "properties.windowsProfile.adminPassword" = var.windows_profile_password_version
  }
  tags           = var.tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
  dynamic "timeouts" {
    for_each = var.cluster_timeouts == null ? [] : [1]

    content {
      create = var.cluster_timeouts.create
      delete = var.cluster_timeouts.delete
      read   = var.cluster_timeouts.read
      update = var.cluster_timeouts.update
    }
  }

  lifecycle {
    # TODO: When https://github.com/Azure/terraform-provider-azapi/pull/1033 is merged, we can remove this.
    ignore_changes = [
      body.properties.kubernetesVersion,
      body.properties.agentPoolProfiles,
    ]
  }
}

moved {
  from = azurerm_kubernetes_cluster.this
  to   = azapi_resource.this
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
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
