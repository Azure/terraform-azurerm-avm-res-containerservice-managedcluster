resource "azapi_resource" "diagnostic_settings" {
  for_each = module.interfaces.diagnostic_settings_azapi_v2

  name                      = coalesce(each.value.name, "diag-${var.name}")
  parent_id                 = azapi_resource.this.id
  type                      = each.value.type
  body                      = each.value.body
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_null_property      = true
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values    = []
  retry                     = var.retry
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

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
