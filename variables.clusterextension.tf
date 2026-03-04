variable "cluster_extension" {
  type = map(object({
    configuration_protected_settings = optional(map(string))
    configuration_settings           = optional(map(string))
    extension_type                   = string
    name                             = string
    plan = optional(object({
      name           = string
      product        = string
      publisher      = string
      promotion_code = optional(string)
      version        = optional(string)
    }))
    release_namespace = optional(string)
    release_train     = optional(string)
    target_namespace  = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
    version = optional(string)
  }))
  default     = {}
  description = <<DESCRIPTION
Map of instances for the cluster extension submodule with the following attributes:

**name**
The name of the cluster extension.

**extension_type**
The extension type. Examples: 'microsoft.dapr', 'microsoft.azureappconfiguration', 'microsoft.storagepoolextension'.

**configuration_protected_settings**
Configuration settings that are protected or sensitive for the extension.

**configuration_settings**
Configuration settings for the extension.

**release_namespace**
Namespace where the extension release must be placed for a cluster scoped extension.

**release_train**
The release train used by this extension. Possible values include but are not limited to 'Stable' or 'Preview'.

**target_namespace**
Namespace where the extension will be created for a namespace scoped extension.

**version**
User-specified version that the extension should pin to. If not set, Azure uses the latest version and auto-upgrades.

**plan**
Plan block for marketplace extensions.

**timeouts**
Timeouts for create, read, update, and delete operations.

DESCRIPTION
}
