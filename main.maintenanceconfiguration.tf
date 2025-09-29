module "maintenance_auto_upgrade" {
  source = "./modules/maintenanceconfiguration"

  cluster_resource_id = azapi_resource.this.id
  duration_hours      = try(var.maintenance_window_auto_upgrade.duration, null)
  frequency           = try(var.maintenance_window_auto_upgrade.frequency, null)
  interval            = try(var.maintenance_window_auto_upgrade.interval, null)
  day_of_month        = try(var.maintenance_window_auto_upgrade.day_of_month, null)
  day_of_week         = try(var.maintenance_window_auto_upgrade.day_of_week, null)
  enable              = var.maintenance_window_auto_upgrade != null
  enable_telemetry    = var.enable_telemetry
  not_allowed_end     = try(var.maintenance_window_auto_upgrade.not_allowed.end, null)
  not_allowed_start   = try(var.maintenance_window_auto_upgrade.not_allowed.start, null)
  start_date          = try(var.maintenance_window_auto_upgrade.start_date, null)
  start_time          = try(var.maintenance_window_auto_upgrade.start_time, null)
  user_agent_header   = local.avm_azapi_header
  utc_offset          = try(var.maintenance_window_auto_upgrade.utc_offset, null)
  week_index          = try(var.maintenance_window_auto_upgrade.week_index, null)
}
