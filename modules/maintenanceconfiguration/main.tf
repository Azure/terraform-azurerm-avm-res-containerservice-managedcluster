resource "azapi_resource" "this" {
  name                   = var.name
  parent_id              = var.parent_id
  type                   = var.resource_types.containerservice_managed_clusters_maintenance_configurations
  body                   = local.resource_body
  ignore_body_changes    = length(var.ignore_body_changes.containerservice_managed_clusters_maintenance_configurations) > 0 ? var.ignore_body_changes.containerservice_managed_clusters_maintenance_configurations : null
  response_export_values = []
  retry                  = var.retry
  # AzAPI's embedded AKS schema does not include 2026-03-01 yet.
  # Azure still validates the request at apply time.
  schema_validation_enabled = false

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
