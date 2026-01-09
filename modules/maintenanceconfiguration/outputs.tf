output "resource_id" {
  description = "Resource ID of the maintenance configuration."
  value       = try(azapi_resource.this[0].id, null)
}
