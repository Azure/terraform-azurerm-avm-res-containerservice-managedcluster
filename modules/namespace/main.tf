resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.ContainerService/managedClusters/managedNamespaces@2025-10-01"
  body      = local.resource_body
  locks = [
    var.parent_id
  ]
  response_export_values = []
  tags                   = var.tags
}
