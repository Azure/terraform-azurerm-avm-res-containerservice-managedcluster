resource "azapi_resource" "this" {
  name                   = var.name
  parent_id              = var.parent_id
  type                   = "Microsoft.ContainerService/managedClusters/maintenanceConfigurations@2026-03-01"
  body                   = local.resource_body
  response_export_values = []
  # AzAPI's embedded AKS schema does not include 2026-03-01 yet.
  # Azure still validates the request at apply time.
  schema_validation_enabled = false
}
