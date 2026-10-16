output "cluster_id" {
  value       = module.aks.resource_id
  description = "ARM resource ID of the new AKS cluster."
}

output "cluster_name" {
  value       = module.aks.name
  description = "Name of the new AKS cluster, including its generated suffix when no name is supplied."
}

output "private_fqdn" {
  value       = module.aks.private_fqdn
  description = "Private API-server FQDN; access requires connectivity and DNS resolution through the approved private network."
}

output "oidc_issuer_url" {
  value       = module.aks.oidc_issuer_profile_issuer_url
  description = "OIDC issuer URL to use when separately configuring workload federated credentials."
}
