output "acr_registry_id" {
  value = azapi_resource.acr.id
}

output "acr_registry_name" {
  value = azapi_resource.acr.name
}

output "aks_cluster_name" {
  value = module.stateful_workloads.name
}

output "aks_kubelet_identity_id" {
  value = module.stateful_workloads.kubelet_identity.objectId
}

output "aks_nodepool_resource_ids" {
  value = module.stateful_workloads.agentpool_resource_ids
}

output "aks_oidc_issuer_url" {
  value = module.stateful_workloads.oidc_issuer_profile_issuer_url
}

output "identity_name" {
  value = length(azapi_resource.mongodb_identity) > 0 ? azapi_resource.mongodb_identity[0].name : ""
}

output "identity_name_client_id" {
  value = length(azapi_resource.mongodb_identity) > 0 ? azapi_resource.mongodb_identity[0].output.properties.clientId : ""
}

output "identity_name_id" {
  value = length(azapi_resource.mongodb_identity) > 0 ? azapi_resource.mongodb_identity[0].id : ""
}

output "identity_name_principal_id" {
  value = length(azapi_resource.mongodb_identity) > 0 ? azapi_resource.mongodb_identity[0].output.properties.principalId : ""
}

output "identity_name_tenant_id" {
  value = length(azapi_resource.mongodb_identity) > 0 ? azapi_resource.mongodb_identity[0].output.properties.tenantId : ""
}

output "key_vault_id" {
  value = azapi_resource.key_vault.id
}

output "key_vault_uri" {
  value = azapi_resource.key_vault.output.properties.vaultUri
}

output "storage_account_key" {
  sensitive = true
  value     = length(data.azapi_resource_action.mongodb_storage_keys) > 0 ? data.azapi_resource_action.mongodb_storage_keys[0].output.keys[0].value : ""
}

output "storage_account_name" {
  value = length(azapi_resource.mongodb_storage) > 0 ? azapi_resource.mongodb_storage[0].name : ""
}
