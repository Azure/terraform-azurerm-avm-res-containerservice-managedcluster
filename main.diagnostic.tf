data "azapi_resource_list" "diagnostic_settings_categories" {
  count = local.has_named_diagnostic_log_categories ? 1 : 0

  parent_id = azapi_resource.this.id
  type      = "Microsoft.Insights/diagnosticSettingsCategories@2021-05-01-preview"
  response_export_values = {
    log_categories = "value[?properties.categoryType == 'Logs'].name"
  }

  depends_on = [azapi_resource.this]
}

resource "azapi_resource" "diagnostic_settings" {
  for_each = module.interfaces.diagnostic_settings_azapi_v2

  name      = coalesce(each.value.name, "diag-${var.name}")
  parent_id = azapi_resource.this.id
  type      = each.value.type
  body = merge(each.value.body, {
    properties = merge(each.value.body.properties, {
      logs = [
        for log in local.diagnostic_setting_logs[each.key] : {
          category      = log.category
          categoryGroup = log.category_group
          enabled       = log.enabled
          retentionPolicy = {
            days    = 0
            enabled = false
          }
        }
      ]
    })
  })
  ignore_null_property      = true
  response_export_values    = []
  retry                     = var.retry
  schema_validation_enabled = false

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
