resource "azapi_resource" "this" {
  name                   = var.name
  parent_id              = var.parent_id
  type                   = "Microsoft.ContainerService/managedClusters/maintenanceConfigurations@2025-10-01"
  body                   = local.resource_body
  response_export_values = []
}
