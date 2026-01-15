output "body_properties" {
  description = "If output_data_only is set to true, this output will contain the properties of the resource as defined in the body. Otherwise, it will be null."
  value       = var.output_data_only ? merge(local.resource_body.properties, { name = var.name }) : null
}

output "current_orchestrator_version" {
  description = "The version of Kubernetes the Agent Pool is running. If orchestratorVersion is a fully specified version <major.minor.patch>, this field will be exactly equal to it. If orchestratorVersion is <major.minor>, this field will contain the full <major.minor.patch> version being used."
  value       = try(azapi_resource.this[0].output.properties.currentOrchestratorVersion, null)
}

output "local_dns_profile_state" {
  description = "System-generated state of localDNS."
  value       = try(azapi_resource.this[0].output.properties.localDNSProfile.state, null)
}

output "name" {
  description = "The name of the created resource."
  value       = var.output_data_only ? null : azapi_resource.this[0].name
}

output "node_image_version" {
  description = "The version of node image"
  value       = try(azapi_resource.this[0].output.properties.nodeImageVersion, null)
}

output "provisioning_state" {
  description = "The current deployment or provisioning state."
  value       = try(azapi_resource.this[0].output.properties.provisioningState, null)
}

output "resource_id" {
  description = "The ID of the created resource."
  value       = var.output_data_only ? null : azapi_resource.this[0].id
}

output "type" {
  description = "Resource type"
  value       = try(azapi_resource.this[0].output.type, null)
}
