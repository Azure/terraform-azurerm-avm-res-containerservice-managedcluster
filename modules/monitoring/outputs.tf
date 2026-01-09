output "container_insights_dcr_id" {
  description = "The resource ID of the Container Insights data collection rule"
  value       = azapi_resource.dcr_msci.id
}

output "data_collection_endpoint_id" {
  description = "The resource ID of the data collection endpoint"
  value       = azapi_resource.dce_msprom.id
}

output "data_collection_rule_id" {
  description = "The resource ID of the data collection rule"
  value       = azapi_resource.dcr_msprom.id
}

output "prometheus_rule_group_node_id" {
  description = "The resource ID of the node Prometheus rule group"
  value       = azapi_resource.prg_node.id
}

output "prometheus_rule_group_ux_id" {
  description = "The resource ID of the UX Prometheus rule group"
  value       = azapi_resource.prg_ux.id
}

output "resource_id" {
  description = "The resource ID of the primary data collection rule created by this module"
  value       = azapi_resource.dcr_msprom.id
}
