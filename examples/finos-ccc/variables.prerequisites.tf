variable "ignore_body_changes" {
  type = object({
    containerservice_managed_clusters = optional(object({
      containerservice_managed_clusters = optional(list(string), [])
    }), {})
  })
  default     = {}
  description = "Body-relative ignore paths passed to AKS unchanged. Only tags may be ignored; ignored configuration is not sent to Azure until the path is removed and changes take effect only after apply. Published prerequisite AVMs own their lifecycle interfaces."
  nullable    = false

  validation {
    condition     = alltrue([for path in var.ignore_body_changes.containerservice_managed_clusters.containerservice_managed_clusters : path == "tags"])
    error_message = "Only tags may be ignored; AKS security settings cannot be suppressed."
  }
}

variable "resource_types" {
  type = object({
    compute_disk_encryption_sets             = optional(string, "Microsoft.Compute/diskEncryptionSets@2024-03-02")
    keyvault_vaults                          = optional(string, "Microsoft.KeyVault/vaults@2024-11-01")
    keyvault_vaults_keys                     = optional(string, "Microsoft.KeyVault/vaults/keys@2024-11-01")
    managedidentity_user_assigned_identities = optional(string, "Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30")
    containerservice_managed_clusters = optional(object({
      containerservice_managed_clusters             = optional(string)
      containerservice_managed_clusters_agent_pools = optional(string)
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
API versions for the ARM key creation, read-only prerequisite lookups and the AKS module. Published prerequisite AVMs own their resource API versions.

- `compute_disk_encryption_sets` - Read the new DES principal ID.
- `keyvault_vaults` - Validate an existing vault without adopting it.
- `keyvault_vaults_keys` - Create the KMS and disk keys through Azure Resource Manager.
- `managedidentity_user_assigned_identities` - Read an existing control-plane principal ID.
- `containerservice_managed_clusters` - Overrides passed to AKS unchanged.
- `containerservice_managed_clusters.containerservice_managed_clusters` - AKS cluster API version, also used to read the cluster back for the CN08 add-on check.
- `containerservice_managed_clusters.containerservice_managed_clusters_agent_pools` - Default agent pool API version.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default = {
    error_message_regex  = ["AuthorizationFailed", "LinkedAuthorizationFailed", "MissingPermission", "PrincipalNotFound"]
    interval_seconds     = 30
    max_interval_seconds = 120
  }
  description = "AKS retry configuration. The default retries transient authorization errors while new role assignments propagate. Null uses provider defaults. Published prerequisite AVMs own their retry behavior; this input does not configure them."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Optional AKS operation timeouts, such as 30m or 1h. Null uses provider defaults. Published prerequisite AVMs own their timeout behavior; this input does not configure them."
}
