resource "azapi_resource" "this" {
  name                      = var.name
  parent_id                 = var.parent_id
  type                      = "Microsoft.ContainerService/managedClusters/maintenanceConfigurations@2026-03-01"
  body                      = local.resource_body
  schema_validation_enabled = false
  response_export_values    = []
}
