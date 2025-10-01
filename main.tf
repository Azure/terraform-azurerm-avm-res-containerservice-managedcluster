data "azurerm_client_config" "current" {}

resource "azapi_resource" "this" {
  location  = var.location
  name      = "${var.name}${var.cluster_suffix}"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.ContainerService/managedClusters@2025-07-01"
  body = {
    properties = local.properties_final
    sku        = var.sku
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = [
    "properties.oidcIssuerProfile.issuerURL",
    "properties.identityProfile",
    "properties.nodeResourceGroup"
  ]
  schema_validation_enabled = false
  tags                      = var.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  identity {
    type         = try(length(local.managed_identities.user_assigned.this.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned", "SystemAssigned")
    identity_ids = try(length(local.managed_identities.user_assigned.this.user_assigned_resource_ids) > 0 ? local.managed_identities.user_assigned.this.user_assigned_resource_ids : null, null)
  }

  lifecycle {
    ignore_changes = [
      body.properties.kubernetesVersion
    ]

    precondition {
      condition     = local.is_automatic || var.cost_analysis_enabled != true || (var.sku_tier == "Standard" || var.sku_tier == "Premium")
      error_message = "`sku_tier` must be either `Standard` or `Premium` when cost analysis is enabled."
    }
    precondition {
      condition     = !var.onboard_monitoring || (local.monitor_workspace_id != null && local.log_analytics_workspace_id != null)
      error_message = "`onboard_monitoring` requires both `monitor_workspace_id` and `log_analytics_workspace_id` (or legacy `oms_agent.log_analytics_workspace_id`)."
    }
    precondition {
      condition     = !var.onboard_alerts || (var.alert_email != null && trimspace(var.alert_email) != "")
      error_message = "`onboard_alerts` requires a non-empty `alert_email`."
    }
    precondition {
      condition     = local.is_automatic || local.automatic_channel_upgrade_check
      error_message = "Either disable automatic upgrades, or specify `kubernetes_version` or `orchestrator_version` only up to the minor version when using `automatic_channel_upgrade=patch`. You don't need to specify `kubernetes_version` at all when using `automatic_channel_upgrade=stable|rapid|node-image`, where `orchestrator_version` always must be set to `null`."
    }
    precondition {
      condition     = local.is_automatic || var.role_based_access_control_enabled || !(var.azure_active_directory_role_based_access_control != null)
      error_message = "Enabling Azure Active Directory integration requires that `role_based_access_control_enabled` be set to true."
    }
    precondition {
      condition     = local.is_automatic || var.key_management_service == null || try(!var.managed_identities.system_assigned, false)
      error_message = "KMS etcd encryption doesn't work with system-assigned managed identity."
    }
    precondition {
      condition     = local.is_automatic || !var.workload_identity_enabled || var.oidc_issuer_enabled
      error_message = "`oidc_issuer_enabled` must be set to `true` to enable Azure AD Workload Identity"
    }
    precondition {
      condition     = local.is_automatic || (var.dns_prefix != null) != (var.dns_prefix_private_cluster != null)
      error_message = "Exactly one of `dns_prefix` or `dns_prefix_private_cluster` must be specified (non-null and non-empty)."
    }
    precondition {
      condition     = local.is_automatic || (var.dns_prefix_private_cluster == null) || (var.private_dns_zone_id != null)
      error_message = "When `dns_prefix_private_cluster` is set, `private_dns_zone_id` must be set."
    }
    precondition {
      condition     = local.is_automatic || var.automatic_upgrade_channel != "node-image" || var.node_os_channel_upgrade == "NodeImage"
      error_message = "`node_os_channel_upgrade` must be set to `NodeImage` if `automatic_channel_upgrade` has been set to `node-image`."
    }
    precondition {
      condition     = local.is_automatic || var.node_pools == null || var.default_node_pool.type == "VirtualMachineScaleSets"
      error_message = "The 'type' variable must be set to 'VirtualMachineScaleSets' if 'node_pools' is not null."
    }
  }
}

moved {
  from = azurerm_kubernetes_cluster.this
  to   = azapi_resource.this
}

# Retrieve kubeconfig(s) & full cluster for outputs
resource "azapi_resource_action" "this_user_kubeconfig" {
  count = local.is_automatic ? 0 : 1

  action                 = "listClusterUserCredential"
  method                 = "POST"
  resource_id            = azapi_resource.this.id
  type                   = azapi_resource.this.type
  response_export_values = ["kubeconfigs"]
}

resource "azapi_resource_action" "this_admin_kubeconfig" {
  count = local.is_automatic ? 0 : 1

  action                 = "listClusterAdminCredential"
  method                 = "POST"
  resource_id            = azapi_resource.this.id
  type                   = azapi_resource.this.type
  response_export_values = ["kubeconfigs"]
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

resource "random_string" "dns_prefix" {
  length  = 10
  lower   = true
  numeric = true
  special = false
  upper   = false
}
