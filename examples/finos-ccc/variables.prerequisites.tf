variable "key_vault_private_endpoint_subnet_id" {
  type        = string
  nullable    = false
  description = "Existing non-delegated subnet ARM ID for the runner's vault private endpoint. Required even for full reuse, when no endpoint is created. Runner routing, NSGs and TCP 443 access must already work."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.key_vault_private_endpoint_subnet_id))
    error_message = "key_vault_private_endpoint_subnet_id must be a subnet ARM ID."
  }

  validation {
    condition     = lower(var.key_vault_private_endpoint_subnet_id) != lower(var.api_server_subnet_id) && lower(var.key_vault_private_endpoint_subnet_id) != lower(var.subnet_id)
    error_message = "Use a dedicated private-endpoint subnet, distinct from the AKS node and delegated API-server subnets."
  }
}

variable "key_vault_private_dns_zone_id" {
  type        = string
  nullable    = true
  description = "Required explicit choice: an existing privatelink.vaultcore.azure.net DNS zone ARM ID, or null to create it through AVM when keys are created. Existing zones are not imported. For full key/DES reuse no vault endpoint or DNS resources are created."

  validation {
    condition     = var.key_vault_private_dns_zone_id == null || can(provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", var.key_vault_private_dns_zone_id))
    error_message = "key_vault_private_dns_zone_id must be a private DNS zone ARM ID or explicit null."
  }

  validation {
    condition     = var.key_vault_private_dns_zone_id == null ? true : try(lower(provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", var.key_vault_private_dns_zone_id).name) == "privatelink.vaultcore.azure.net", false)
    error_message = "The vault private DNS zone must be named privatelink.vaultcore.azure.net."
  }
}

variable "key_vault_dns_virtual_network_links" {
  type        = map(string)
  nullable    = false
  description = "Required map of NEW DNS link names to existing VNet ARM IDs for vault resolution (runner VNet or DNS-forwarding hub). For a new zone supply at least one link when creating keys. For an existing zone use {} if links already exist; existing links are never adopted. Routing and custom DNS forwarding remain external."

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
    condition     = var.key_vault_private_dns_zone_id != null || (var.key_vault_key_id != null && var.disk_encryption_set_id != null) || length(var.key_vault_dns_virtual_network_links) > 0
    error_message = "Creating a vault DNS zone for key management requires at least one runner/resolver VNet link."
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
  nullable    = false
  description = <<DESCRIPTION
API versions for read-only prerequisite lookups and the AKS module. Published prerequisite AVMs own their resource API versions.

- `compute_disk_encryption_sets` - Read the new DES principal ID.
- `keyvault_vaults` - Validate an existing vault without adopting it.
- `managedidentity_user_assigned_identities` - Read an existing control-plane principal ID.
- `containerservice_managed_clusters` - Overrides passed to AKS unchanged.
- `containerservice_managed_clusters.containerservice_managed_clusters` - AKS cluster API version.
- `containerservice_managed_clusters.containerservice_managed_clusters_agent_pools` - Default agent pool API version.
DESCRIPTION
}

variable "ignore_body_changes" {
  type = object({
    containerservice_managed_clusters = optional(object({
      containerservice_managed_clusters = optional(list(string), [])
    }), {})
  })
  default     = {}
  nullable    = false
  description = "Body-relative ignore paths passed to AKS unchanged. Only tags may be ignored; ignored configuration is not sent to Azure until the path is removed and changes take effect only after apply. Published prerequisite AVMs own their lifecycle interfaces."

  validation {
    condition     = alltrue([for path in var.ignore_body_changes.containerservice_managed_clusters.containerservice_managed_clusters : path == "tags"])
    error_message = "Only tags may be ignored; AKS security settings cannot be suppressed."
  }
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Optional AKS retry configuration. Null uses provider defaults. Published prerequisite AVMs own their retry behavior; this input does not configure them."
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
