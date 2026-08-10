locals {
  aks_cluster_id = "${var.parent_id}/providers/Microsoft.ContainerService/managedClusters/${var.name}"
  managed_identities = {
    system_assigned_user_assigned = var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
