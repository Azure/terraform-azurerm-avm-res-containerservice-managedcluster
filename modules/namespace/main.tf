resource "azapi_resource" "this" {
  location            = var.location
  name                = var.name
  parent_id           = var.parent_id
  type                = var.resource_types.containerservice_managed_clusters_managed_namespaces
  body                = local.resource_body
  ignore_body_changes = length(var.ignore_body_changes.containerservice_managed_clusters_managed_namespaces) > 0 ? var.ignore_body_changes.containerservice_managed_clusters_managed_namespaces : null
  retry               = var.retry
  locks = [
    var.parent_id
  ]
  response_export_values = []
  # AzAPI's embedded AKS schema does not include 2026-03-01 yet.
  # Azure still validates the request at apply time.
  schema_validation_enabled = false
  tags                      = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
