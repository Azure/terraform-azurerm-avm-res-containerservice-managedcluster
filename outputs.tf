output "aci_connector_object_id" {
  description = "(Not directly available via azapi without extra GET)"
  value       = null
}

output "cluster_ca_certificate" {
  description = "Base64 cluster CA certificate from user kubeconfig."
  sensitive   = true
  value = try(
    base64encode(
      yamldecode(
        try(azapi_resource_action.this_user_kubeconfig[0].output.kubeconfigs[0].value, "")
      ).clusters[0].cluster["certificate-authority-data"]
    ),
    null
  )
}

output "host" {
  description = "API server host from user kubeconfig."
  sensitive   = true
  value = try(
    yamldecode(
      try(azapi_resource_action.this_user_kubeconfig[0].output.kubeconfigs[0].value, "")
    ).clusters[0].cluster.server,
    null
  )
}

output "ingress_app_object_id" {
  description = "Ingress Application identity object id (not currently extracted)."
  value       = null
}

output "key_vault_secrets_provider_object_id" {
  description = "Key vault secrets provider identity object id (not currently extracted)."
  value       = null
}

output "kube_admin_config" {
  description = "Admin kubeconfig raw YAML (sensitive)."
  sensitive   = true
  value       = try(azapi_resource_action.this_admin_kubeconfig[0].output.kubeconfigs[0].value, null)
}

output "kube_config" {
  description = "User kubeconfig raw YAML (sensitive)."
  sensitive   = true
  value       = try(azapi_resource_action.this_user_kubeconfig[0].output.kubeconfigs[0].value, null)
}

output "kubelet_identity_id" {
  description = "Kubelet identity object id (not currently extracted)."
  # Exposed when the managed cluster populates identityProfile.kubeletidentity
  # If absent (e.g., preview features disabled), this will be null.
  value = try(azapi_resource.this.output.properties.identityProfile.kubeletidentity.objectId, null)
}

output "name" {
  description = "Name of the Kubernetes cluster."
  value       = azapi_resource.this.name
}

output "node_resource_group_id" {
  description = "Node resource group name not exported; manual lookup required."
  value       = null
}

output "node_resource_group_name" {
  description = "Name of the automatically created node resource group."
  value       = try(azapi_resource.this.output.properties.nodeResourceGroup, null)
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
  description = "OIDC issuer URL from GET export values."
  value       = try(azapi_resource.this.output.properties.oidcIssuerProfile.issuerURL, null)
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = var.private_endpoints_manage_dns_zone_group ? azurerm_private_endpoint.this_managed_dns_zone_groups : azurerm_private_endpoint.this_unmanaged_dns_zone_groups
}

output "public_fqdn" {
  description = "Returns .fqdn when both private_cluster_enabled and private_cluster_public_fqdn_enabled are true, otherwise null"
  value = (
    var.api_server_access_profile != null && var.api_server_access_profile.enable_private_cluster_public_fqdn
  ) ? azapi_resource.this.output.properties.fqdn : null
}

output "resource_id" {
  description = "Resource ID of the Kubernetes cluster."
  value       = azapi_resource.this.id
}

output "user_assigned_identity_client_ids" {
  description = "Map of identity profile keys to clientIds."
  value       = try({ for k, v in azapi_resource.this.output.properties.identityProfile : k => v.clientId }, {})
}

output "user_assigned_identity_object_ids" {
  description = "Map of identity profile keys to principalIds."
  value       = try({ for k, v in azapi_resource.this.output.properties.identityProfile : k => v.objectId }, {})
}

output "web_app_routing_client_id" {
  description = "The object ID of the web app routing identity"
  value       = try(azapi_resource.this.output.properties.ingressProfile.webAppRouting.identity.clientId, null)
}

output "web_app_routing_object_id" {
  description = "Web app routing identity object id (not currently extracted)."
  value       = null
}
