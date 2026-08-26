locals {
  aks_cluster_id = "${var.parent_id}/providers/Microsoft.ContainerService/managedClusters/${var.name}"
  # `timeouts` is the AVM-standard input; `cluster_timeouts` is retained for backwards compatibility.
  effective_timeouts = var.timeouts != null ? var.timeouts : var.cluster_timeouts
  managed_identities = {
    system_assigned_user_assigned = var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
  # Private endpoint creation races the resource lock, so retry on ScopeLocked unless the consumer overrides it.
  private_endpoint_retry = var.retry != null ? var.retry : {
    error_message_regex  = ["ScopeLocked"]
    interval_seconds     = 15
    max_interval_seconds = 60
  }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
