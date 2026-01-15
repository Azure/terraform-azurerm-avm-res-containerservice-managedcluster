module "maintenanceconfiguration" {
  source   = "./modules/maintenanceconfiguration"
  for_each = var.maintenanceconfiguration

  name               = each.value.name
  parent_id          = azapi_resource.this.id
  enable_telemetry   = each.value.enable_telemetry
  maintenance_window = each.value.maintenance_window
  not_allowed_time   = each.value.not_allowed_time
  time_in_week       = each.value.time_in_week
}
