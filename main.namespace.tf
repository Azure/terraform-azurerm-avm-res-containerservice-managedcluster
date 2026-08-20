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
  ignore_body_changes    = var.ignore_body_changes.containerservice_managed_clusters_managed_namespaces
  labels                 = each.value.labels
  resource_types         = var.resource_types.containerservice_managed_clusters_managed_namespaces
  retry                  = var.retry
  tags                   = each.value.tags
  timeouts               = var.timeouts == null ? var.cluster_timeouts : var.timeouts
}
