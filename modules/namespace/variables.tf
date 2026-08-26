variable "default_resource_quota" {
  type = object({
    cpu_limit      = optional(string)
    cpu_request    = optional(string)
    memory_limit   = optional(string)
    memory_request = optional(string)
  })
  description = <<DESCRIPTION
Resource quota for the namespace. This is required by the Azure API even though the API spec marks it as optional.

- `cpu_limit` - CPU limit of the namespace in one-thousandth CPU form. See [CPU resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-cpu) for more details.
- `cpu_request` - CPU request of the namespace in one-thousandth CPU form. See [CPU resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-cpu) for more details.
- `memory_limit` - Memory limit of the namespace in the power-of-two equivalents form: Ei, Pi, Ti, Gi, Mi, Ki. See [Memory resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-memory) for more details.
- `memory_request` - Memory request of the namespace in the power-of-two equivalents form: Ei, Pi, Ti, Gi, Mi, Ki. See [Memory resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-memory) for more details.

DESCRIPTION
  nullable    = false
}

variable "location" {
  type        = string
  description = <<DESCRIPTION
The location of the resource.
DESCRIPTION
  nullable    = false
}

variable "name" {
  type        = string
  description = <<DESCRIPTION
The name of the resource.
DESCRIPTION

  validation {
    condition     = length(var.name) >= 1
    error_message = "name must have a minimum length of 1."
  }
  validation {
    condition     = length(var.name) <= 63
    error_message = "name must have a maximum length of 63."
  }
  validation {
    condition     = can(regex("[a-z0-9]([-a-z0-9]*[a-z0-9])?", var.name))
    error_message = "name must match the pattern: [a-z0-9]([-a-z0-9]*[a-z0-9])?."
  }
}

variable "parent_id" {
  type        = string
  description = <<DESCRIPTION
The parent resource ID for this resource.
DESCRIPTION
}

variable "adoption_policy" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Action if Kubernetes namespace with same name already exists.
DESCRIPTION

  validation {
    condition     = var.adoption_policy == null || contains(["Always", "IfIdentical", "Never"], var.adoption_policy)
    error_message = "adoption_policy must be one of: [\"Always\", \"IfIdentical\", \"Never\"]."
  }
}

variable "annotations" {
  type        = map(string)
  default     = null
  description = <<DESCRIPTION
The annotations of managed namespace.
DESCRIPTION
}

variable "default_network_policy" {
  type = object({
    egress  = optional(string)
    ingress = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Default network policy of the namespace, specifying ingress and egress rules.

- `egress` - Enum representing different network policy rules.
- `ingress` - Enum representing different network policy rules.

DESCRIPTION

  validation {
    condition     = try(var.default_network_policy == null || var.default_network_policy.egress == null || contains(["AllowAll", "AllowSameNamespace", "DenyAll"], var.default_network_policy.egress), true)
    error_message = "default_network_policy.egress must be one of: [\"AllowAll\", \"AllowSameNamespace\", \"DenyAll\"]."
  }
  validation {
    condition     = try(var.default_network_policy == null || var.default_network_policy.ingress == null || contains(["AllowAll", "AllowSameNamespace", "DenyAll"], var.default_network_policy.ingress), true)
    error_message = "default_network_policy.ingress must be one of: [\"AllowAll\", \"AllowSameNamespace\", \"DenyAll\"]."
  }
}

variable "delete_policy" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Delete options of a namespace.
DESCRIPTION

  validation {
    condition     = var.delete_policy == null || contains(["Delete", "Keep"], var.delete_policy)
    error_message = "delete_policy must be one of: [\"Delete\", \"Keep\"]."
  }
}

variable "ignore_body_changes" {
  type = object({
    containerservice_managed_clusters_managed_namespaces = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths to ignore for each AzAPI resource, in dot notation. Changes take
effect only after apply, and ignored configuration is not sent to Azure until the
path is removed.

- `containerservice_managed_clusters_managed_namespaces` - Paths ignored on the managed namespace.
DESCRIPTION
  nullable    = false
}

variable "labels" {
  type        = map(string)
  default     = null
  description = <<DESCRIPTION
The labels of managed namespace.
DESCRIPTION
}

variable "resource_types" {
  type = object({
    containerservice_managed_clusters_managed_namespaces = optional(string, "Microsoft.ContainerService/managedClusters/managedNamespaces@2026-03-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by this module.

- `containerservice_managed_clusters_managed_namespaces` - Resource type and API version for the managed namespace.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to the AzAPI resources in this module.

- `error_message_regex` - Regular expressions matching error messages that should be retried.
- `interval_seconds` - Initial delay between retries, in seconds.
- `max_interval_seconds` - Maximum delay between retries, in seconds.
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = null
  description = <<DESCRIPTION
A mapping of tags to assign to the resource.
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
Timeouts applied to the AzAPI resources in this module.

- `create` - Timeout for create operations.
- `read` - Timeout for read operations.
- `update` - Timeout for update operations.
- `delete` - Timeout for delete operations.
DESCRIPTION
}
