output "azure_portal_fqdn" {
  description = "The special FQDN used by the Azure Portal to access the Managed Cluster. This FQDN is for use only by the Azure Portal and should not be used by other clients. The Azure Portal requires certain Cross-Origin Resource Sharing (CORS) headers to be sent in some responses, which Kubernetes APIServer doesn't handle by default. This special FQDN supports CORS, allowing the Azure Portal to function properly."
  value       = try(azapi_resource.this.output.properties.azurePortalFQDN, null)
}

output "cluster_ca_certificate" {
  description = "Base64 cluster CA certificate from user kubeconfig."
  value       = nonsensitive(local.kubeconfig_user != null ? yamldecode(local.kubeconfig_user).clusters[0].cluster.certificate-authority-data : null)
}

output "current_kubernetes_version" {
  description = "The version of Kubernetes the Managed Cluster is running. If kubernetesVersion was a fully specified version <major.minor.patch>, this field will be exactly equal to it. If kubernetesVersion was <major.minor>, this field will contain the full <major.minor.patch> version being used."
  value       = try(azapi_resource.this.output.properties.currentKubernetesVersion, null)
}

output "fqdn" {
  description = "The FQDN of the master pool."
  value       = try(azapi_resource.this.output.properties.fqdn, null)
}

output "identity_principal_id" {
  description = "The principal id of the system assigned identity which is used by master components."
  value       = try(azapi_resource.this.output.identity.principalId, null)
}

output "identity_tenant_id" {
  description = "The tenant id of the system assigned identity which is used by master components."
  value       = try(azapi_resource.this.output.identity.tenantId, null)
}

output "ingress_profile_web_app_routing_identity" {
  description = "Details about a user assigned identity."
  value       = try(azapi_resource.this.output.properties.ingressProfile.webAppRouting.identity, {})
}

output "key_vault_secrets_provider_identity" {
  description = "The identity of the Key Vault Secrets Provider addon, including clientId, objectId, and resourceId."
  value       = try(azapi_resource.this.output.properties.addonProfiles.azureKeyvaultSecretsProvider.identity, null)
}

output "kube_admin_config" {
  description = "Admin kubeconfig raw YAML (sensitive)."
  sensitive   = true
  value       = local.kubeconfig_admin
}

output "kube_config" {
  description = "User kubeconfig raw YAML (sensitive)."
  sensitive   = true
  value       = local.kubeconfig_user
}

output "kubelet_identity" {
  description = "The kubelet identity of the managed cluster, including clientId, objectId, and resourceId."
  value       = try(azapi_resource.this.output.properties.identityProfile.kubeletidentity, null)
}

output "max_agent_pools" {
  description = "The max number of agent pools for the managed cluster."
  value       = try(azapi_resource.this.output.properties.maxAgentPools, null)
}

output "name" {
  description = "The name of the created resource."
  value       = azapi_resource.this.name
}

output "network_profile_load_balancer_profile_effective_outbound_ips" {
  description = "The effective outbound IP resources of the cluster load balancer."
  value       = try(azapi_resource.this.output.properties.networkProfile.loadBalancerProfile.effectiveOutboundIPs, [])
}

output "network_profile_nat_gateway_profile_effective_outbound_ips" {
  description = "The effective outbound IP resources of the cluster NAT gateway."
  value       = try(azapi_resource.this.output.properties.networkProfile.natGatewayProfile.effectiveOutboundIPs, [])
}

output "node_resource_group_name" {
  description = "The name of the auto-created node resource group."
  value       = try(azapi_resource.this.output.properties.nodeResourceGroup, null)
}

output "oidc_issuer_profile_issuer_url" {
  description = "The OIDC issuer url of the Managed Cluster."
  value       = try(azapi_resource.this.output.properties.oidcIssuerProfile.issuerURL, null)
}

output "private_fqdn" {
  description = "The FQDN of private cluster."
  value       = try(azapi_resource.this.output.properties.privateFQDN, null)
}

output "resource_id" {
  description = "The ID of the created resource."
  value       = azapi_resource.this.id
}
