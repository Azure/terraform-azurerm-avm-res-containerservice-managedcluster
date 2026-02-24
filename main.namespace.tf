module "namespace" {
  source   = "./modules/namespace"
  for_each = var.namespace

  default_resource_quota = each.value.default_resource_quota
  location               = each.value.location != null ? each.value.location : var.location
  name                   = each.value.name
  parent_id              = azapi_resource.this.id
  adoption_policy        = each.value.adoption_policy
  annotations            = each.value.annotations
  default_network_policy = each.value.default_network_policy
  delete_policy          = each.value.delete_policy
  labels                 = each.value.labels
  tags                   = each.value.tags
}
