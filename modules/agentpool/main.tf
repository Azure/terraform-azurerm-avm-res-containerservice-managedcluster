moved {
  from = azurerm_kubernetes_cluster_node_pool.this[0]
  to   = azapi_resource.this[0]
}

moved {
  from = azurerm_kubernetes_cluster_node_pool.create_before_destroy_node_pool[0]
  to   = azapi_resource.this_create_before_destroy[0]
}

resource "azapi_resource" "this" {
  count = var.output_data_only ? 0 : var.create_before_destroy ? 0 : 1

  name                  = var.name
  parent_id             = var.parent_id
  type                  = "Microsoft.ContainerService/managedClusters/agentPools@2025-10-01"
  body                  = local.resource_body
  ignore_null_property  = true
  replace_triggers_refs = local.replace_triggers_refs
  response_export_values = [
    "properties.currentOrchestratorVersion",
    "properties.localDNSProfile.state",
    "properties.nodeImageVersion",
    "properties.provisioningState",
    "type"
  ]

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

resource "azapi_resource" "this_create_before_destroy" {
  count = var.output_data_only ? 0 : var.create_before_destroy ? 1 : 0

  name                  = "${var.name}${substr(sha256(uuid()), 0, 4)}"
  parent_id             = var.parent_id
  type                  = "Microsoft.ContainerService/managedClusters/agentPools@2025-10-01"
  body                  = local.resource_body
  ignore_null_property  = true
  replace_triggers_refs = local.replace_triggers_refs
  response_export_values = [
    "properties.currentOrchestratorVersion",
    "properties.localDNSProfile.state",
    "properties.nodeImageVersion",
    "properties.provisioningState",
    "type"
  ]

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      name
    ]
    replace_triggered_by = [terraform_data.name_keeper]
  }
}

resource "terraform_data" "name_keeper" {
  triggers_replace = {
    name = var.name
  }
}
locals {
  created_resource = try(azapi_resource.this[0], azapi_resource.this_create_before_destroy[0], null)
}
