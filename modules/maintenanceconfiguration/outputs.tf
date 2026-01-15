output "name" {
  description = "The name of the created resource."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "The ID of the created resource."
  value       = azapi_resource.this.id
}

output "system_data" {
  description = "Metadata pertaining to creation and last modification of the resource."
  value       = try(azapi_resource.this.output.systemData, {})
}

output "type" {
  description = "Resource type"
  value       = try(azapi_resource.this.output.type, null)
}
