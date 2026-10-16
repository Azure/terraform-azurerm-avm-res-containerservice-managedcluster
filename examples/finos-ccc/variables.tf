variable "name" {
  description = "Optional new cluster name. When null, a unique aks-ccc name is generated and retained in state. Never target an existing cluster with new state."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_id" {
  description = "Existing resource group ARM ID for the cluster and newly created prerequisites."
  type        = string
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.resource_group_id))
    error_message = "resource_group_id must be a resource group ARM ID."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version supported in the selected region."
  type        = string
}

variable "control_plane_identity_id" {
  description = "Existing control-plane user-assigned identity ARM ID, or null to create one. Existing-to-existing grants remain the caller's responsibility."
  type        = string
  default     = null

  validation {
    condition     = var.control_plane_identity_id == null || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", var.control_plane_identity_id))
    error_message = "control_plane_identity_id must be a user-assigned identity ARM ID or null."
  }
}

variable "kubelet_identity_id" {
  description = "Existing kubelet user-assigned identity ARM ID (not an object/client ID), or null to create one distinct from the control-plane identity."
  type        = string
  default     = null

  validation {
    condition     = var.kubelet_identity_id == null || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", var.kubelet_identity_id))
    error_message = "kubelet_identity_id must be a user-assigned identity ARM ID or null."
  }

  validation {
    condition     = var.kubelet_identity_id == null || var.control_plane_identity_id == null ? true : lower(var.kubelet_identity_id) != lower(var.control_plane_identity_id)
    error_message = "The control-plane and kubelet identities must be distinct."
  }
}

variable "cluster_admin_group_object_ids" {
  description = "Entra GROUP object IDs for Kubernetes cluster-admin access."
  type        = list(string)

  validation {
    condition     = length(var.cluster_admin_group_object_ids) > 0
    error_message = "Supply at least one Entra admin group."
  }
}

variable "private_dns_zone_id" {
  description = "Existing API private DNS zone ARM ID, including a cross-subscription zone, or null to create a unique subzone of private.<location>.azmk8s.io and link it to the existing cluster VNet. Existing zone links are not managed."
  type        = string
  default     = null

  validation {
    condition     = var.private_dns_zone_id == null || can(provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", var.private_dns_zone_id))
    error_message = "private_dns_zone_id must be a private DNS zone ARM ID or null."
  }
}

variable "subnet_id" {
  description = "Existing AKS node subnet with UDR and permitted AKS egress."
  type        = string
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.subnet_id))
    error_message = "subnet_id must be a subnet ARM ID."
  }
}

variable "api_server_subnet_id" {
  description = "Existing delegated API-server subnet for VNet integration and private KMS."
  type        = string
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.api_server_subnet_id))
    error_message = "api_server_subnet_id must be a subnet ARM ID."
  }

  validation {
    condition = try(
      lower(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.api_server_subnet_id).parent_id) == lower(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.subnet_id).parent_id) && lower(var.api_server_subnet_id) != lower(var.subnet_id),
      false
    )
    error_message = "Node and API-server subnets must be distinct subnets in the same VNet."
  }
}

variable "disk_encryption_set_id" {
  description = "Existing disk encryption set ARM ID with usable CMK/grants, or null to create a system-assigned DES and a separate disk key in the selected vault. Existing DES keys and grants are not managed."
  type        = string
  default     = null

  validation {
    condition     = var.disk_encryption_set_id == null || can(provider::azapi::parse_resource_id("Microsoft.Compute/diskEncryptionSets", var.disk_encryption_set_id))
    error_message = "disk_encryption_set_id must be a disk encryption set ARM ID or null."
  }
}

variable "key_vault_key_id" {
  description = "Existing versioned KMS key HTTPS URL, paired with key_vault_resource_id, or null to create a separate RSA KMS key in the selected vault. This is a data-plane URL, not an ARM key ID."
  type        = string
  default     = null

  validation {
    condition     = var.key_vault_key_id == null || can(regex("^https://[^/]+/keys/[a-zA-Z0-9-]+/[a-zA-Z0-9]+$", var.key_vault_key_id))
    error_message = "key_vault_key_id must be a versioned HTTPS Key Vault key URL or null."
  }

  validation {
    condition     = var.key_vault_key_id == null || var.key_vault_resource_id != null
    error_message = "An existing KMS key URL requires its existing key_vault_resource_id."
  }

  validation {
    condition = var.key_vault_key_id == null ? true : try(
      startswith(lower(split("/", var.key_vault_key_id)[2]), "${lower(provider::azapi::parse_resource_id("Microsoft.KeyVault/vaults", var.key_vault_resource_id).name)}."),
      false
    )
    error_message = "The KMS key URL must belong to the supplied Key Vault."
  }
}

variable "key_vault_resource_id" {
  description = "Existing KMS vault ARM ID, or null to create a private, RBAC-enabled, purge-protected vault. Creating keys or new identity grants in an existing vault requires RBAC mode; creating a DES also requires purge protection and the cluster region."
  type        = string
  default     = null

  validation {
    condition     = var.key_vault_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.KeyVault/vaults", var.key_vault_resource_id))
    error_message = "key_vault_resource_id must be a Key Vault ARM ID or null."
  }
}

variable "service_cidr" {
  description = "Service CIDR; verify no overlap with VNet/connected networks or fixed pod CIDR 172.18.0.0/16."
  type        = string
}

variable "dns_service_ip" {
  description = "DNS service IP within service_cidr."
  type        = string
}

variable "tags" {
  description = "Approved ownership, billing and security tags applied unchanged to resources that support tags."
  type        = map(string)
  nullable    = false
}
