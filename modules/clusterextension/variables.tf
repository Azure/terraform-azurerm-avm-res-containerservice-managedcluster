variable "cluster_id" {
  type        = string
  description = <<DESCRIPTION
The ID of the Kubernetes cluster.
DESCRIPTION
}

variable "extension_type" {
  type        = string
  description = <<DESCRIPTION
The extension type. Examples: 'microsoft.dapr', 'microsoft.azureappconfiguration', 'microsoft.storagepoolextension'.
DESCRIPTION

  validation {
    condition     = length(var.extension_type) >= 1
    error_message = "extension_type must have a minimum length of 1."
  }
}

variable "name" {
  type        = string
  description = <<DESCRIPTION
The name of the cluster extension.
DESCRIPTION

  validation {
    condition     = length(var.name) >= 1
    error_message = "name must have a minimum length of 1."
  }
  validation {
    condition     = length(var.name) <= 253
    error_message = "name must have a maximum length of 253."
  }
}

variable "configuration_protected_settings" {
  type        = map(string)
  default     = {}
  description = <<DESCRIPTION
Configuration settings that are protected or sensitive for the extension.
DESCRIPTION
}

variable "configuration_settings" {
  type        = map(string)
  default     = {}
  description = <<DESCRIPTION
Configuration settings for the extension.
DESCRIPTION
}

variable "extension_version" {
  type        = string
  default     = null
  description = <<DESCRIPTION
User-specified version that the extension should pin to. If not set, Azure uses the latest version and auto-upgrades.
DESCRIPTION
}

variable "plan" {
  type = object({
    name           = string
    product        = string
    publisher      = string
    promotion_code = optional(string)
    version        = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Plan block for marketplace extensions.
DESCRIPTION
}

variable "release_namespace" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Namespace where the extension release must be placed for a cluster scoped extension.
DESCRIPTION
}

variable "release_train" {
  type        = string
  default     = null
  description = <<DESCRIPTION
The release train used by this extension. Possible values include but are not limited to 'Stable' or 'Preview'.
DESCRIPTION
}

variable "target_namespace" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Namespace where the extension will be created for a namespace scoped extension.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Timeouts for create, read, update, and delete operations.
DESCRIPTION
}
