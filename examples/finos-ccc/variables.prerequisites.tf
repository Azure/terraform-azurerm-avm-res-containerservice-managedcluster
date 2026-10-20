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

variable "key_vault_dns_virtual_network_links" {
  type        = map(string)
  default     = {}
  description = "Map of NEW DNS link names to existing VNet ARM IDs for vault resolution (runner VNet or DNS-forwarding hub). When the network is created, the created runner VNet is linked automatically. Do not link the cluster VNet: AKS private KMS links its own zone there. Existing links are never adopted."
  nullable    = false

  validation {
    condition     = alltrue([for id in values(var.key_vault_dns_virtual_network_links) : can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks", id))])
    error_message = "Every vault DNS link value must be a VNet ARM ID."
  }
  validation {
    condition     = alltrue([for name in keys(var.key_vault_dns_virtual_network_links) : length(name) > 0 && length(name) < 80])
    error_message = "Vault DNS link names must contain 1 to 79 characters."
  }
  validation {
    condition     = length(distinct([for id in values(var.key_vault_dns_virtual_network_links) : lower(id)])) == length(var.key_vault_dns_virtual_network_links)
    error_message = "Create only one link per VNet in the vault DNS zone."
  }
  validation {
    condition     = var.key_vault_private_dns_zone_id != null || (var.key_vault_key_id != null && var.disk_encryption_set_id != null) || length(var.key_vault_dns_virtual_network_links) > 0 || var.subnet_id == null
    error_message = "Creating a vault DNS zone for key management with existing subnets requires at least one runner/resolver VNet link."
  }
}

variable "key_vault_private_dns_zone_id" {
  type        = string
  default     = null
  description = "Existing privatelink.vaultcore.azure.net DNS zone ARM ID, or null to create it through AVM when keys are created. Existing zones are not imported. For full key/DES reuse no vault endpoint or DNS resources are created."

  validation {
    condition     = var.key_vault_private_dns_zone_id == null || can(provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", var.key_vault_private_dns_zone_id))
    error_message = "key_vault_private_dns_zone_id must be a private DNS zone ARM ID or null."
  }
  validation {
    condition     = var.key_vault_private_dns_zone_id == null ? true : try(lower(provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", var.key_vault_private_dns_zone_id).name) == "privatelink.vaultcore.azure.net", false)
    error_message = "The vault private DNS zone must be named privatelink.vaultcore.azure.net."
  }
}

variable "key_vault_private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "Existing non-delegated subnet ARM ID for the deployment runner's Key Vault private endpoint, or null when the network is created (the endpoint then goes into the created runner VNet). Runner routing, NSGs and TCP 443 access must work."

  validation {
    condition     = var.key_vault_private_endpoint_subnet_id == null || can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.key_vault_private_endpoint_subnet_id))
    error_message = "key_vault_private_endpoint_subnet_id must be a subnet ARM ID or null."
  }
}

variable "resource_types" {
  type = object({
    compute_disk_encryption_sets             = optional(string, "Microsoft.Compute/diskEncryptionSets@2024-03-02")
    keyvault_vaults                          = optional(string, "Microsoft.KeyVault/vaults@2024-11-01")
    managedidentity_user_assigned_identities = optional(string, "Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30")
    containerservice_managed_clusters = optional(object({
      containerservice_managed_clusters             = optional(string)
      containerservice_managed_clusters_agent_pools = optional(string)
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
API versions for read-only prerequisite lookups and the AKS module. Published prerequisite AVMs own their resource API versions.

- `compute_disk_encryption_sets` - Read the new DES principal ID.
- `keyvault_vaults` - Validate an existing vault without adopting it.
- `managedidentity_user_assigned_identities` - Read an existing control-plane principal ID.
- `containerservice_managed_clusters` - Overrides passed to AKS unchanged.
- `containerservice_managed_clusters.containerservice_managed_clusters` - AKS cluster API version.
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
