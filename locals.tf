locals {
  automatic_channel_upgrade_check = var.automatic_upgrade_channel == null ? true : (
    (contains(["patch"], var.automatic_upgrade_channel) && can(regex("^[0-9]{1,}\\.[0-9]{1,}$", var.kubernetes_version)) && (can(regex("^[0-9]{1,}\\.[0-9]{1,}$", var.default_node_pool.orchestrator_version)) || var.default_node_pool.orchestrator_version == null)) ||
    (contains(["rapid", "stable", "node-image"], var.automatic_upgrade_channel) && var.kubernetes_version == null && var.default_node_pool.orchestrator_version == null)
  )
  dns_prefix = coalesce(var.dns_prefix, random_string.dns_prefix.result)
  managed_identities = {
    system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
  private_dns_prefix = coalesce(var.dns_prefix_private_cluster, random_string.dns_prefix.result)
  # Private endpoint application security group associations.
  # We merge the nested maps from private endpoints and application security group associations into a single map.
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
