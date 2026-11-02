module "maintenanceconfiguration" {
  source   = "./modules/maintenanceconfiguration"
  for_each = var.maintenanceconfiguration

  name               = each.value.name
  parent_id          = azapi_resource.this.id
  enable_telemetry   = var.enable_telemetry
  location           = var.location
  maintenance_window = each.value.maintenance_window
  not_allowed_time   = each.value.not_allowed_time
  retry              = var.retry
  time_in_week       = each.value.time_in_week
  timeouts           = local.effective_timeouts
}
