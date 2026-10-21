output "control_plane_identity_id" {
  description = "ARM ID of the created or reused control-plane identity."
  value       = local.control_plane_identity_id
}

output "kubelet_identity_id" {
  description = "ARM ID of the distinct created or reused kubelet identity."
  value       = local.kubelet_identity_id
}

output "private_dns_zone_id" {
  description = "ARM ID of the created or reused API-server private DNS zone."
  value       = local.private_dns_zone_id
}

output "key_vault_resource_id" {
  description = "ARM ID of the created or reused KMS vault."
  value       = local.key_vault_resource_id
}

output "key_vault_key_id" {
  description = "Versionless HTTPS URL of the created or reused KMS key, as configured on the cluster."
  value       = local.key_vault_key_id
}

output "disk_encryption_set_id" {
  description = "ARM ID of the created or reused node disk encryption set."
  value       = local.disk_encryption_set_id
}

output "disk_key_id" {
  description = "Versioned disk-key URL when a DES is created; null when reusing a DES, whose key remains externally managed."
  value       = var.disk_encryption_set_id == null ? module.encryption_keys["disk"].id : null
}

output "key_vault_private_dns_zone_id" {
  description = "Selected vault private DNS zone ARM ID; null for full key/DES reuse with an explicit null DNS input."
  value       = local.key_vault_private_dns_zone_id
}

output "key_vault_private_endpoint_id" {
  description = "Runner vault private endpoint ARM ID, or null when no keys are managed by this example."
  value       = local.create_key_vault_endpoint ? module.key_vault_endpoint[0].resource_id : null
}
