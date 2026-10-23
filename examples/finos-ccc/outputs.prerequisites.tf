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
  description = "HTTPS URL of the created or reused KMS key as configured on the cluster: versioned, or versionless when kms_key_versionless is true."
  value       = local.key_vault_key_id
}

output "disk_encryption_set_id" {
  description = "ARM ID of the created or reused node disk encryption set."
  value       = local.disk_encryption_set_id
}

output "disk_key_id" {
  description = "Versioned disk-key URL when a DES is created; null when reusing a DES, whose key remains externally managed."
  value       = var.disk_encryption_set_id == null ? azapi_resource_action.encryption_keys["disk"].output.properties.keyUriWithVersion : null
}
