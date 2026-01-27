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
    condition     = var.default_network_policy == null || var.default_network_policy.egress == null || contains(["AllowAll", "AllowSameNamespace", "DenyAll"], var.default_network_policy.egress)
    error_message = "default_network_policy.egress must be one of: [\"AllowAll\", \"AllowSameNamespace\", \"DenyAll\"]."
  }
  validation {
    condition     = var.default_network_policy == null || var.default_network_policy.ingress == null || contains(["AllowAll", "AllowSameNamespace", "DenyAll"], var.default_network_policy.ingress)
    error_message = "default_network_policy.ingress must be one of: [\"AllowAll\", \"AllowSameNamespace\", \"DenyAll\"]."
  }
}

variable "default_resource_quota" {
  type = object({
    cpu_limit      = optional(string)
    cpu_request    = optional(string)
    memory_limit   = optional(string)
    memory_request = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Resource quota for the namespace.

- `cpu_limit` - CPU limit of the namespace in one-thousandth CPU form. See [CPU resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-cpu) for more details.
- `cpu_request` - CPU request of the namespace in one-thousandth CPU form. See [CPU resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-cpu) for more details.
- `memory_limit` - Memory limit of the namespace in the power-of-two equivalents form: Ei, Pi, Ti, Gi, Mi, Ki. See [Memory resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-memory) for more details.
- `memory_request` - Memory request of the namespace in the power-of-two equivalents form: Ei, Pi, Ti, Gi, Mi, Ki. See [Memory resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-memory) for more details.

DESCRIPTION
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

variable "labels" {
  type        = map(string)
  default     = null
  description = <<DESCRIPTION
The labels of managed namespace.
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = null
  description = <<DESCRIPTION
A mapping of tags to assign to the resource.
DESCRIPTION
}
