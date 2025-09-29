# Monitoring module - conditionally instantiated
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.onboard_monitoring ? 1 : 0

  aks_cluster_id             = azapi_resource.this.id
  aks_cluster_name           = azapi_resource.this.name
  location                   = var.location
  log_analytics_workspace_id = local.log_analytics_workspace_id
  monitor_workspace_id       = local.monitor_workspace_id
  resource_group_name        = var.resource_group_name
  subscription_id            = data.azurerm_client_config.current.subscription_id
}

# Alerting module - conditionally instantiated
module "alerting" {
  source = "./modules/alerting"
  count  = var.onboard_alerts && var.alert_email != null && trimspace(var.alert_email) != "" ? 1 : 0

  aks_cluster_id      = azapi_resource.this.id
  aks_cluster_name    = azapi_resource.this.name
  alert_email         = var.alert_email
  resource_group_name = var.resource_group_name
  subscription_id     = data.azurerm_client_config.current.subscription_id
}
