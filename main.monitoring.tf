# Monitoring module - conditionally instantiated
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.onboard_monitoring ? 1 : 0

  aks_cluster_id               = azapi_resource.this.id
  location                     = var.location
  log_analytics_workspace_id   = var.log_analytics_workspace_id
  managed_grafana_workspace_id = var.managed_grafana_workspace_id
  parent_id                    = var.parent_id
}

# Alerting module - conditionally instantiated
module "alerting" {
  source = "./modules/alerting"
  count  = var.onboard_alerts ? 1 : 0

  aks_cluster_id = azapi_resource.this.id
  alert_email    = var.alert_email
  parent_id      = var.parent_id
}
