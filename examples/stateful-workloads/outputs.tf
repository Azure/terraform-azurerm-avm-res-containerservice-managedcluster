output "acr_registry_id" {
  value = module.avm_res_containerregistry_registry.resource_id
}

output "acr_registry_name" {
  value = module.avm_res_containerregistry_registry.name
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
  value = length(module.mongodb) > 0 ? module.mongodb[0].identity_name : ""
}

output "identity_name_client_id" {
  value = length(module.mongodb) > 0 ? module.mongodb[0].identity_name_client_id : ""
}

output "identity_name_id" {
  value = length(module.mongodb) > 0 ? module.mongodb[0].identity_name_id : ""
}

output "identity_name_principal_id" {
  value = length(module.mongodb) > 0 ? module.mongodb[0].identity_name_principal_id : ""
}

output "identity_name_tenant_id" {
  value = length(module.mongodb) > 0 ? module.mongodb[0].identity_name_tenant_id : ""
}

output "key_vault_id" {
  value = module.avm_res_keyvault_vault.resource_id
}

output "key_vault_uri" {
  value = module.avm_res_keyvault_vault.uri
}

output "storage_account_key" {
  sensitive = true
  value     = length(module.mongodb) > 0 ? module.mongodb[0].storage_account_key : ""
}

output "storage_account_name" {
  value = length(module.mongodb) > 0 ? module.mongodb[0].storage_account_name : ""
}
