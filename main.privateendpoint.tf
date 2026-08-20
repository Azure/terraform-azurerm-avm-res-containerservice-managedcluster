resource "azapi_resource" "private_endpoints" {
  for_each = module.interfaces.private_endpoints_azapi

  location = coalesce(var.private_endpoints[each.key].location, var.location)
  name     = each.value.name
  parent_id = var.private_endpoints[each.key].resource_group_name == null ? var.parent_id : format(
    "/subscriptions/%s/resourceGroups/%s",
    split("/", var.parent_id)[2],
    var.private_endpoints[each.key].resource_group_name
  )
  type = var.resource_types.network_private_endpoints
  body = merge(each.value.body, {
    properties = merge(each.value.body.properties, {
      customNetworkInterfaceName = var.private_endpoints[each.key].network_interface_name
    })
  })
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes       = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  ignore_null_property      = true
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_refs     = ["properties.subnet.id"]
  response_export_values    = []
  retry                     = var.retry
  schema_validation_enabled = false
  tags                      = each.value.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? (var.cluster_timeouts == null ? [] : [var.cluster_timeouts]) : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource" "private_dns_zone_groups" {
  for_each = {
    for key, private_dns_zone_group in module.interfaces.private_dns_zone_groups_azapi :
    key => private_dns_zone_group if length(var.private_endpoints[key].private_dns_zone_resource_ids) > 0
  }

  name      = each.value.name
  parent_id = azapi_resource.private_endpoints[each.key].id
  type      = var.resource_types.network_private_endpoints_private_dns_zone_groups
  body = merge(each.value.body, {
    properties = merge(each.value.body.properties, {
      privateDnsZoneConfigs = [
        for private_dns_zone_resource_id in var.private_endpoints[each.key].private_dns_zone_resource_ids : {
          name = basename(private_dns_zone_resource_id)
          properties = {
            privateDnsZoneId = private_dns_zone_resource_id
          }
        }
      ]
    })
  })
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_body_changes       = length(var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups) > 0 ? var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups : null
  ignore_null_property      = true
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_refs     = []
  response_export_values    = []
  retry                     = var.retry
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? (var.cluster_timeouts == null ? [] : [var.cluster_timeouts]) : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
