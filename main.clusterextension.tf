module "clusterextension" {
  source   = "./modules/clusterextension"
  for_each = var.cluster_extension

  cluster_id                       = azapi_resource.this.id
  extension_type                   = each.value.extension_type
  name                             = each.value.name
  configuration_protected_settings = each.value.configuration_protected_settings
  configuration_settings           = each.value.configuration_settings
  extension_version                = each.value.version
  plan                             = each.value.plan
  release_namespace                = each.value.release_namespace
  release_train                    = each.value.release_train
  target_namespace                 = each.value.target_namespace
  timeouts                         = each.value.timeouts
}
