variable "namespace" {
  type = map(object({
    adoption_policy = optional(string)
    annotations     = optional(map(string))
    default_network_policy = optional(object({
      egress  = optional(string)
      ingress = optional(string)
    }))
    default_resource_quota = optional(object({
      cpu_limit      = optional(string)
      cpu_request    = optional(string)
      memory_limit   = optional(string)
      memory_request = optional(string)
    }))
    delete_policy    = optional(string)
    enable_telemetry = optional(bool)
    labels           = optional(map(string))
    name             = string
    tags             = optional(map(string))
  }))
  default     = {}
  description = <<DESCRIPTION
Map of instances for the submodule with the following attributes:

**enable_telemetry**
This variable controls whether or not telemetry is enabled for the module. For more information see https://aka.ms/avm/telemetryinfo.

**name**
The name of the resource.

**annotations**
The annotations of managed namespace.

**default_network_policy**
Default network policy of the namespace, specifying ingress and egress rules.

- `egress` - Enum representing different network policy rules.
- `ingress` - Enum representing different network policy rules.


**delete_policy**
Delete options of a namespace.

**labels**
The labels of managed namespace.

**tags**
A mapping of tags to assign to the resource.

**adoption_policy**
Action if Kubernetes namespace with same name already exists.

**default_resource_quota**
Resource quota for the namespace.

- `cpu_limit` - CPU limit of the namespace in one-thousandth CPU form. See [CPU resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-cpu) for more details.
- `cpu_request` - CPU request of the namespace in one-thousandth CPU form. See [CPU resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-cpu) for more details.
- `memory_limit` - Memory limit of the namespace in the power-of-two equivalents form: Ei, Pi, Ti, Gi, Mi, Ki. See [Memory resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-memory) for more details.
- `memory_request` - Memory request of the namespace in the power-of-two equivalents form: Ei, Pi, Ti, Gi, Mi, Ki. See [Memory resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-memory) for more details.
DESCRIPTION
}
