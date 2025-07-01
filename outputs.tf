output "aci_connector_object_id" {
  description = "The object ID of the ACI Connector identity"
  value       = try(azurerm_kubernetes_cluster.this.aci_connector_linux[0].connector_identity[0].object_id, null)
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the AKS cluster."
  sensitive   = true
  value       = azurerm_kubernetes_cluster.this.kube_config
}

output "host" {
  description = "The host of the AKS cluster API server."
  sensitive   = true
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
}

output "ingress_app_object_id" {
  description = "The object ID of the Ingress Application identity"
  value       = try(azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id, null)
}

output "key_vault_secrets_provider_object_id" {
  description = "The object ID of the key vault secrets provider."
  value       = try(azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id, null)
}

output "kube_admin_config" {
  description = "The kube_admin_config block of the AKS cluster, only available when Local Accounts & Role-Based Access Control (RBAC) with AAD are enabled."
  sensitive   = true
  value       = local.kube_admin_enabled ? azurerm_kubernetes_cluster.this.kube_admin_config : null
}

output "kube_config" {
  description = "The kube_config block of the AKS cluster"
  sensitive   = true
  value       = azurerm_kubernetes_cluster.this.kube_config
}

output "kubelet_identity_id" {
  description = "The identity ID of the kubelet identity."
  value       = try(azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id, null)
}

output "name" {
  description = "Name of the Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "node_resource_group_id" {
  description = "The resource group ID of the node resource group."
  value       = azurerm_kubernetes_cluster.this.node_resource_group_id
}

output "nodepool_resource_ids" {
  description = "A map of nodepool keys to resource ids."
  value = { for npk, np in module.nodepools : npk => {
    resource_id = np.resource_id
    name        = np.name
    }
  }
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL of the Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
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

output "web_app_routing_object_id" {
  description = "The object ID of the web app routing identity"
  value       = try(azurerm_kubernetes_cluster.this.web_app_routing[0].web_app_routing_identity[0].object_id, null)
}
