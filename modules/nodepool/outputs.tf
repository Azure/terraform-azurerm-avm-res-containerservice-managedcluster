output "name" {
  description = "Name of the Kubernetes node pool."
  value       = var.create_nodepool_before_destroy ? azapi_resource.create_before_destroy_node_pool[0].name : azapi_resource.this[0].name
}

output "properties" {
  description = "Full response body properties of the node pool (from AzAPI)."
  value       = var.create_nodepool_before_destroy ? azapi_resource.create_before_destroy_node_pool[0].output.properties : azapi_resource.this[0].output.properties
}

output "resource_id" {
  description = "Resource ID of the Kubernetes node pool."
  value       = var.create_nodepool_before_destroy ? azapi_resource.create_before_destroy_node_pool[0].id : azapi_resource.this[0].id
}
