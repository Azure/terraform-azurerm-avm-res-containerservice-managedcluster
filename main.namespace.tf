module "namespace" {
  source   = "./modules/namespace"
  for_each = var.namespace

  name                   = each.value.name
  parent_id              = azapi_resource.this.id
  adoption_policy        = each.value.adoption_policy
  annotations            = each.value.annotations
  default_network_policy = each.value.default_network_policy
  default_resource_quota = each.value.default_resource_quota
  delete_policy          = each.value.delete_policy
  labels                 = each.value.labels
  tags                   = each.value.tags
}
