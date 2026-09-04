resource "azapi_resource" "private_endpoints" {
  for_each = module.interfaces.private_endpoints_azapi

  location = coalesce(var.private_endpoints[each.key].location, var.location)
  name     = each.value.name
  parent_id = var.private_endpoints[each.key].resource_group_name == null ? var.parent_id : format(
    "/subscriptions/%s/resourceGroups/%s",
    split("/", var.parent_id)[2],
    var.private_endpoints[each.key].resource_group_name
  )
  type = each.value.type
  body = merge(each.value.body, {
    properties = merge(each.value.body.properties, {
      customNetworkInterfaceName = var.private_endpoints[each.key].network_interface_name
    })
  })
  ignore_null_property      = true
  replace_triggers_refs     = ["properties.subnet.id"]
  response_export_values    = []
  retry                     = local.private_endpoint_retry
  schema_validation_enabled = false
  tags                      = each.value.tags

  dynamic "timeouts" {
    for_each = local.effective_timeouts == null ? [] : [local.effective_timeouts]

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
  type      = each.value.type
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
  ignore_null_property      = true
  response_export_values    = []
  retry                     = local.private_endpoint_retry
  schema_validation_enabled = false

  dynamic "timeouts" {
    for_each = local.effective_timeouts == null ? [] : [local.effective_timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
