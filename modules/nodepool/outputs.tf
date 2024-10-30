output "name" {
  description = "Name of the Kubernetes cluster."
  value       = var.create_nodepool_before_destroy ? azurerm_kubernetes_cluster_node_pool.create_before_destroy_node_pool[0].name : azurerm_kubernetes_cluster_node_pool.this[0].name
}

output "resource_id" {
  description = "Resource ID of the Kubernetes cluster."
  value       = var.create_nodepool_before_destroy ? azurerm_kubernetes_cluster_node_pool.create_before_destroy_node_pool[0].id : azurerm_kubernetes_cluster_node_pool.this[0].id
}
