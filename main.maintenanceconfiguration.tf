module "maintenanceconfiguration" {
  source   = "./modules/maintenanceconfiguration"
  for_each = var.maintenanceconfiguration

  name                = each.value.name
  parent_id           = azapi_resource.this.id
  ignore_body_changes = var.ignore_body_changes.containerservice_managed_clusters_maintenance_configurations
  maintenance_window  = each.value.maintenance_window
  not_allowed_time    = each.value.not_allowed_time
  resource_types      = var.resource_types.containerservice_managed_clusters_maintenance_configurations
  retry               = var.retry
  time_in_week        = each.value.time_in_week
  timeouts            = var.timeouts == null ? var.cluster_timeouts : var.timeouts
}
