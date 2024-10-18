resource "azurerm_kubernetes_cluster_extension" "this" {
  count                            = var.flux_extension != null ? 1 : 0
  name                             = var.flux_extension.name
  cluster_id                       = azurerm_kubernetes_cluster.this.id
  extension_type                   = var.flux_extension.type
  configuration_settings           = var.flux_extension.configuration_settings
  configuration_protected_settings = var.flux_extension.protected_settings
  dynamic "plan" {
    for_each = var.flux_extension.plan != null ? [var.flux_extension.plan] : []
    content {
      name      = plan.value.name
      version   = plan.value.version
      publisher = plan.value.publisher
      product   = plan.value.product
    }
  }

  release_namespace = var.flux_extension.release_namespace
  release_train     = var.flux_extension.release_train
  target_namespace  = var.flux_extension.target_namespace
  version           = var.flux_extension.version
}
