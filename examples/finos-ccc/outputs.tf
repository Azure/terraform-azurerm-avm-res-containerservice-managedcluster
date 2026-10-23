output "cluster_id" {
  description = "ARM resource ID of the new AKS cluster."
  value       = module.aks.resource_id
}

output "cluster_name" {
  description = "Name of the new AKS cluster, including its generated suffix when no name is supplied."
  value       = module.aks.name
}

output "private_fqdn" {
  description = "Private API-server FQDN; access requires connectivity and DNS resolution through the approved private network."
  value       = module.aks.private_fqdn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL used by the workload identity federated credentials."
  value       = module.aks.oidc_issuer_profile_issuer_url
}

output "resource_group_id" {
  description = "ARM ID of the created or reused resource group."
  value       = local.resource_group_id
}

output "log_analytics_workspace_id" {
  description = "ARM ID of the Log Analytics workspace receiving Kubernetes audit, control-plane and Defender data."
  value       = module.log_analytics.resource_id
}

output "container_registry_login_server" {
  description = "Login server of the approved private container registry. Admitted images must use this registry and an @sha256 digest."
  value       = module.container_registry.login_server
}

output "workload_identity_client_ids" {
  description = "Client ID of each namespace's workload identity, for the `azure.workload.identity/client-id` service account annotation."
  value       = { for name, identity in module.workload_identities : name => identity.client_id }
}
