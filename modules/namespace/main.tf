resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.ContainerService/managedClusters/managedNamespaces@2026-03-01"
  body      = local.resource_body
  locks = [
    var.parent_id
  ]
  response_export_values = []
  # AzAPI's embedded AKS schema does not include 2026-03-01 yet.
  # Azure still validates the request at apply time.
  schema_validation_enabled = false
  tags                      = var.tags
}
