output "key_vault_secrets_provider_object_id" {
  description = "The object ID of the key vault secrets provider."
  value       = try(azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id, null)
}

output "kubelet_identity_id" {
  description = "The identity ID of the kubelet identity."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "name" {
  description = "Name of the Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "nodepool_resource_ids" {
  description = "A map of nodepool keys to resource ids."
  value = { for npk, np in module.nodepools : npk => {
    resource_id = np.resource_id
    name        = np.name
    }
  }
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

output "resource_id" {
  description = "Resource ID of the Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.this.id
}
