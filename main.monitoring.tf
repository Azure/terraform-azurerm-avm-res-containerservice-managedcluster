# Monitoring module - conditionally instantiated
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.onboard_monitoring ? 1 : 0

  aks_cluster_id             = local.aks_cluster_id
  location                   = var.location
  log_analytics_workspace_id = var.addon_profile_oms_agent.config.log_analytics_workspace_resource_id
  parent_id                  = var.parent_id
  prometheus_workspace_id    = var.prometheus_workspace_id
  resource_types             = var.resource_types.insights_data_collection_endpoints
  retry                      = var.retry
  tags                       = var.tags
  timeouts                   = var.timeouts == null ? var.cluster_timeouts : var.timeouts
  ignore_body_changes        = var.ignore_body_changes.insights_data_collection_endpoints

  depends_on = [azapi_resource.this]
}

# Alerting module - conditionally instantiated
module "alerting" {
  source = "./modules/alerting"
  count  = var.onboard_alerts ? 1 : 0

  aks_cluster_id      = local.aks_cluster_id
  alert_email         = var.alert_email
  parent_id           = var.parent_id
  resource_types      = var.resource_types.insights_action_groups
  retry               = var.retry
  tags                = var.tags
  timeouts            = var.timeouts == null ? var.cluster_timeouts : var.timeouts
  ignore_body_changes = var.ignore_body_changes.insights_action_groups

  depends_on = [azapi_resource.this]
}
