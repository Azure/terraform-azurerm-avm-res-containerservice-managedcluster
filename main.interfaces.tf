locals {
  diagnostic_settings_v2 = {
    for key, diagnostic_setting in var.diagnostic_settings : key => {
      name = diagnostic_setting.name
      logs = concat(
        [
          for category in diagnostic_setting.log_categories : {
            category       = category
            category_group = null
          }
        ],
        [
          for category_group in diagnostic_setting.log_groups : {
            category       = null
            category_group = category_group
          }
        ]
      )
      metrics = [
        for category in diagnostic_setting.metric_categories : {
          category = category
        }
      ]
      event_hub_authorization_rule_resource_id = diagnostic_setting.event_hub_authorization_rule_resource_id
      event_hub_name                           = diagnostic_setting.event_hub_name
      log_analytics_destination_type           = diagnostic_setting.log_analytics_destination_type
      marketplace_partner_resource_id          = diagnostic_setting.marketplace_partner_resource_id
      storage_account_resource_id              = diagnostic_setting.storage_account_resource_id
      workspace_resource_id                    = diagnostic_setting.workspace_resource_id
    }
  }
  role_assignment_definition_scope = "/subscriptions/${split("/", var.parent_id)[2]}"
}

module "interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.6.0"

  diagnostic_settings_v2 = local.diagnostic_settings_v2
  enable_telemetry       = var.enable_telemetry
  lock                   = var.lock
  role_assignment_definition_lookup_enabled = anytrue([
    for role_assignment in var.role_assignments :
    !strcontains(lower(role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring))
  ])
  role_assignment_definition_scope = local.role_assignment_definition_scope
  role_assignments                 = var.role_assignments
}
