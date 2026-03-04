output "name" {
  description = "The name of the created cluster extension."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "The ID of the created cluster extension."
  value       = azapi_resource.this.id
}
