locals {
  diagnostic_settings_v2 = {
    for key, diagnostic_setting in var.diagnostic_settings : key => {
      name = diagnostic_setting.name
      logs = concat(
        [
          for category in diagnostic_setting.log_categories : {
            category       = category
            category_group = null
            enabled        = true
          }
        ],
        [
          for category_group in diagnostic_setting.log_groups : {
            category       = null
            category_group = category_group
            enabled        = true
          }
        ],
        [
          for category_group in setsubtract(toset(["allLogs", "audit"]), diagnostic_setting.log_groups) : {
            category       = null
            category_group = category_group
            enabled        = false
          }
        ]
      )
      metrics = [
        for category in diagnostic_setting.metric_categories : {
          category = category
          enabled  = true
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
  private_endpoints = {
    for key, private_endpoint in var.private_endpoints : key => {
      application_security_group_associations = private_endpoint.application_security_group_associations
      ip_configurations = {
        for ip_configuration_key, ip_configuration in private_endpoint.ip_configurations :
        ip_configuration_key => merge(ip_configuration, {
          member_name = "management"
        })
      }
      location                      = private_endpoint.location
      lock                          = null
      name                          = coalesce(private_endpoint.name, "pe-${var.name}")
      network_interface_name        = private_endpoint.network_interface_name
      private_dns_zone_group_name   = private_endpoint.private_dns_zone_group_name
      private_dns_zone_resource_ids = private_endpoint.private_dns_zone_resource_ids
      private_service_connection_name = coalesce(
        private_endpoint.private_service_connection_name,
        "pse-${var.name}"
      )
      resource_group_name = private_endpoint.resource_group_name
      role_assignments    = {}
      subnet_resource_id  = private_endpoint.subnet_resource_id
      subresource_name    = "management"
      tags                = private_endpoint.tags
    }
  }
  role_assignment_definition_scope = "/subscriptions/${split("/", var.parent_id)[2]}"
}

module "interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.6.0"

  diagnostic_settings_v2                  = local.diagnostic_settings_v2
  enable_telemetry                        = var.enable_telemetry
  lock                                    = var.lock
  private_endpoints                       = local.private_endpoints
  private_endpoints_manage_dns_zone_group = var.private_endpoints_manage_dns_zone_group
  private_endpoints_scope                 = azapi_resource.this.id
  role_assignment_definition_lookup_enabled = anytrue([
    for role_assignment in var.role_assignments :
    !strcontains(lower(role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring))
  ])
  role_assignment_definition_scope = local.role_assignment_definition_scope
  role_assignments                 = var.role_assignments
}
