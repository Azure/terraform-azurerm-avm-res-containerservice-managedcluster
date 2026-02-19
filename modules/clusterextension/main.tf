resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.cluster_id
  type      = "Microsoft.KubernetesConfiguration/extensions@2023-05-01"
  body = merge(
    {
      properties = merge(
        {
          extensionType = var.extension_type
        },
        var.configuration_protected_settings != null && length(var.configuration_protected_settings) > 0 ? {
          configurationProtectedSettings = var.configuration_protected_settings
        } : {},
        var.configuration_settings != null && length(var.configuration_settings) > 0 ? {
          configurationSettings = var.configuration_settings
        } : {},
        var.extension_version == null ? {} : {
          autoUpgradeMinorVersion = false
          version                 = var.extension_version
        },
        var.release_train == null ? {} : {
          releaseTrain = var.release_train
        },
        var.release_namespace == null && var.target_namespace == null ? {} : {
          scope = merge(
            var.release_namespace == null ? {} : {
              cluster = {
                releaseNamespace = var.release_namespace
              }
            },
            var.target_namespace == null ? {} : {
              namespace = {
                targetNamespace = var.target_namespace
              }
            }
          )
        }
      )
    },
    var.plan == null ? {} : {
      plan = merge(
        {
          name      = var.plan.name
          product   = var.plan.product
          publisher = var.plan.publisher
        },
        var.plan.promotion_code == null ? {} : {
          promotionCode = var.plan.promotion_code
        },
        var.plan.version == null ? {} : {
          version = var.plan.version
        }
      )
    }
  )
  ignore_null_property = true

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
    ignore_changes = [
      body.properties.autoUpgradeMinorVersion,
    ]
  }
}
