variable "api_server_subnet_id" {
  type        = string
  default     = null
  description = "Existing API-server subnet ARM ID delegated to Microsoft.ContainerService/managedClusters (/28 or larger) in the node subnet's VNet, or null when the network is created."

  validation {
    condition     = var.api_server_subnet_id == null || can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.api_server_subnet_id))
    error_message = "api_server_subnet_id must be a subnet ARM ID or null."
  }
}

variable "approved_addons" {
  type        = list(string)
  default     = ["azure_key_vault_kms", "azure_policy", "defender", "image_cleaner", "oms_agent", "workload_identity"]
  description = "Organization-approved allowlist of AKS add-ons and managed security features (CCC.K8S.CN08.AR01). A check fails when the example enables anything else."
  nullable    = false
}

variable "cluster_admin_group_object_ids" {
  type        = list(string)
  default     = []
  description = "Optional break-glass Entra GROUP object IDs that receive Kubernetes cluster-admin through the AAD profile. Day-to-day access uses `cluster_role_assignments`."
  nullable    = false
}

variable "cluster_role_assignments" {
  type = map(object({
    principal_id               = string
    role_definition_id_or_name = string
    principal_type             = optional(string)
  }))
  default     = {}
  description = <<DESCRIPTION
Azure RBAC for Kubernetes role assignments at cluster scope (CCC.K8S.CN02.AR01). Prefer groups
and the narrowest built-in role, for example `Azure Kubernetes Service RBAC Reader` or
`Azure Kubernetes Service RBAC Writer`. When empty, the deploying identity receives
`Azure Kubernetes Service RBAC Cluster Admin` so the example remains operable.

- `principal_id` - Entra object ID of the user, group or service principal.
- `role_definition_id_or_name` - Built-in role name or role definition ID.
- `principal_type` - Optional `User`, `Group` or `ServicePrincipal`.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for assignment in values(var.cluster_role_assignments) : startswith(assignment.role_definition_id_or_name, "Azure Kubernetes Service RBAC ") || startswith(assignment.role_definition_id_or_name, "/")])
    error_message = "Use an Azure Kubernetes Service RBAC built-in role name or a role definition ID."
  }
}

variable "container_cpu_limit" {
  type        = string
  default     = "1000m"
  description = "Maximum CPU limit allowed for any user container by Azure Policy (CCC.K8S.CN13.AR01)."
  nullable    = false
}

variable "container_memory_limit" {
  type        = string
  default     = "2Gi"
  description = "Maximum memory limit allowed for any user container by Azure Policy (CCC.K8S.CN13.AR01)."
  nullable    = false
}

variable "container_registry_private_dns_zone_id" {
  type        = string
  default     = null
  description = "Existing privatelink.azurecr.io DNS zone ARM ID already resolvable from the cluster VNet, or null to create the zone and link it to the cluster VNet."

  validation {
    condition     = var.container_registry_private_dns_zone_id == null ? true : try(lower(provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", var.container_registry_private_dns_zone_id).name) == "privatelink.azurecr.io", false)
    error_message = "container_registry_private_dns_zone_id must be the ARM ID of a privatelink.azurecr.io zone or null."
  }
}

variable "container_registry_private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "Existing subnet ARM ID, reachable from the AKS nodes, for the container registry private endpoint, or null when the network is created."

  validation {
    condition     = var.container_registry_private_endpoint_subnet_id == null || can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.container_registry_private_endpoint_subnet_id))
    error_message = "container_registry_private_endpoint_subnet_id must be a subnet ARM ID or null."
  }
}

variable "control_plane_identity_id" {
  type        = string
  default     = null
  description = "Existing control-plane user-assigned identity ARM ID, or null to create one. Existing-to-existing grants remain the caller's responsibility."

  validation {
    condition     = var.control_plane_identity_id == null || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", var.control_plane_identity_id))
    error_message = "control_plane_identity_id must be a user-assigned identity ARM ID or null."
  }
}

variable "disk_encryption_set_id" {
  type        = string
  default     = null
  description = "Existing disk encryption set ARM ID with usable CMK/grants, or null to create a system-assigned DES and a separate disk key in the selected vault. Existing DES keys and grants are not managed."

  validation {
    condition     = var.disk_encryption_set_id == null || can(provider::azapi::parse_resource_id("Microsoft.Compute/diskEncryptionSets", var.disk_encryption_set_id))
    error_message = "disk_encryption_set_id must be a disk encryption set ARM ID or null."
  }
}

variable "dns_service_ip" {
  type        = string
  default     = "10.20.0.10"
  description = "Kubernetes DNS service IP within service_cidr."
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "key_vault_key_id" {
  type        = string
  default     = null
  description = "Existing versioned KMS key HTTPS URL, paired with key_vault_resource_id, or null to create a separate RSA KMS key in the selected vault. This is a data-plane URL, not an ARM key ID."

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
  type        = string
  default     = null
  description = "Existing KMS vault ARM ID, or null to create a private, RBAC-enabled, purge-protected vault. Creating keys or new identity grants in an existing vault requires RBAC mode; creating a DES also requires purge protection and the cluster region."

  validation {
    condition     = var.key_vault_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.KeyVault/vaults", var.key_vault_resource_id))
    error_message = "key_vault_resource_id must be a Key Vault ARM ID or null."
  }
}

variable "kubelet_identity_id" {
  type        = string
  default     = null
  description = "Existing kubelet user-assigned identity ARM ID (not an object/client ID), or null to create one distinct from the control-plane identity."

  validation {
    condition     = var.kubelet_identity_id == null || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", var.kubelet_identity_id))
    error_message = "kubelet_identity_id must be a user-assigned identity ARM ID or null."
  }
  validation {
    condition     = var.kubelet_identity_id == null || var.control_plane_identity_id == null ? true : lower(var.kubelet_identity_id) != lower(var.control_plane_identity_id)
    error_message = "The control-plane and kubelet identities must be distinct."
  }
}

variable "kubernetes_version" {
  type        = string
  default     = null
  description = "Kubernetes `<major.minor>` version supported in the selected region, or null for the AKS default. The patch upgrade channel keeps the patch level current (CCC.K8S.CN09)."

  validation {
    condition     = var.kubernetes_version == null || can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must be <major.minor> (for example 1.33) so patch auto-upgrades do not cause drift."
  }
}

variable "location" {
  type        = string
  default     = "swedencentral"
  description = "Approved Azure region (CCC.Core.CN06). It must support availability zones 1-3, Trusted Launch, encryption at host and the Standard_D4s_v5 VM size."
  nullable    = false
}

variable "log_analytics_retention_in_days" {
  type        = number
  default     = 90
  description = "Retention for Kubernetes audit, control-plane and security logs in the Log Analytics workspace (CCC.K8S.CN14.AR01)."
  nullable    = false

  validation {
    condition     = var.log_analytics_retention_in_days >= 30 && var.log_analytics_retention_in_days <= 730
    error_message = "log_analytics_retention_in_days must be between 30 and 730."
  }
}

variable "name" {
  type        = string
  default     = null
  description = "Optional new cluster name. When null, a unique aks-ccc name is generated and retained in state. Never target an existing cluster with new state."
}

variable "outbound_type" {
  type        = string
  default     = "loadBalancer"
  description = "AKS outbound type. `userDefinedRouting` requires existing subnets whose route table already sends egress through an approved firewall."
  nullable    = false

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting"], var.outbound_type)
    error_message = "outbound_type must be loadBalancer or userDefinedRouting."
  }
  validation {
    condition     = var.outbound_type != "userDefinedRouting" || var.subnet_id != null
    error_message = "userDefinedRouting requires existing subnets with an approved egress route (subnet_id and related inputs)."
  }
}

variable "private_dns_zone_id" {
  type        = string
  default     = null
  description = "Existing API private DNS zone ARM ID, including a cross-subscription zone, or null to create a unique subzone of private.<location>.azmk8s.io linked to the cluster VNet. Existing zone links are not managed."

  validation {
    condition     = var.private_dns_zone_id == null || can(provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", var.private_dns_zone_id))
    error_message = "private_dns_zone_id must be a private DNS zone ARM ID or null."
  }
}

variable "resource_group_id" {
  type        = string
  default     = null
  description = "Existing resource group ARM ID for the cluster and its prerequisites, or null to create one."

  validation {
    condition     = var.resource_group_id == null || can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.resource_group_id))
    error_message = "resource_group_id must be a resource group ARM ID or null."
  }
}

variable "runner_virtual_network_address_space" {
  type        = string
  default     = "10.11.0.0/24"
  description = "Address space of the created runner VNet (/26 or larger), which hosts the deployment runner and its Key Vault private endpoint."
  nullable    = false

  validation {
    condition     = can(cidrhost(var.runner_virtual_network_address_space, 0)) && tonumber(split("/", var.runner_virtual_network_address_space)[1]) <= 26
    error_message = "runner_virtual_network_address_space must be a CIDR block of /26 or larger."
  }
}

variable "service_cidr" {
  type        = string
  default     = "10.20.0.0/16"
  description = "Kubernetes service CIDR. It must not overlap the VNets, connected networks or the fixed pod CIDR 172.18.0.0/16."
  nullable    = false
}

variable "subnet_id" {
  type        = string
  default     = null
  description = "Existing AKS node subnet ARM ID, or null to create the cluster and runner VNets. Supply all existing subnet inputs together or none of them."

  validation {
    condition     = var.subnet_id == null || can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.subnet_id))
    error_message = "subnet_id must be a subnet ARM ID or null."
  }
  validation {
    condition = (
      (var.subnet_id == null && var.api_server_subnet_id == null && var.key_vault_private_endpoint_subnet_id == null && var.container_registry_private_endpoint_subnet_id == null) ||
      (var.subnet_id != null && var.api_server_subnet_id != null && var.key_vault_private_endpoint_subnet_id != null && var.container_registry_private_endpoint_subnet_id != null)
    )
    error_message = "Supply subnet_id, api_server_subnet_id, key_vault_private_endpoint_subnet_id and container_registry_private_endpoint_subnet_id together, or none of them to create the network."
  }
  validation {
    condition = var.subnet_id == null || var.api_server_subnet_id == null ? true : try(
      lower(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.api_server_subnet_id).parent_id) == lower(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.subnet_id).parent_id) && lower(var.api_server_subnet_id) != lower(var.subnet_id),
      false
    )
    error_message = "Node and API-server subnets must be distinct subnets in the same VNet."
  }
  validation {
    condition     = var.subnet_id == null || var.key_vault_private_endpoint_subnet_id == null ? true : !contains([lower(var.subnet_id), lower(coalesce(var.api_server_subnet_id, "-"))], lower(var.key_vault_private_endpoint_subnet_id))
    error_message = "Use a dedicated Key Vault private-endpoint subnet, distinct from the AKS node and delegated API-server subnets."
  }
}

variable "subscription_id" {
  type        = string
  default     = null
  description = "Subscription ID used when `resource_group_id` is null. When both are null, AzAPI uses the Azure CLI default subscription and AzureRM requires `ARM_SUBSCRIPTION_ID`."
}

variable "tags" {
  type = map(string)
  default = {
    environment         = "demo"
    owner               = "platform-team"
    data-classification = "internal"
  }
  description = "Approved ownership, environment and data-classification tags applied to resources that support tags (CCC.K8S.CN15.AR01)."
  nullable    = false

  validation {
    condition     = alltrue([for key in ["environment", "owner", "data-classification"] : contains(keys(var.tags), key)])
    error_message = "tags must include environment, owner and data-classification (CCC.K8S.CN15.AR01)."
  }
}

variable "virtual_network_address_space" {
  type        = string
  default     = "10.10.0.0/16"
  description = "Address space of the created cluster VNet (/16 or larger). Nodes, the API server and private endpoints receive fixed subnets inside it."
  nullable    = false

  validation {
    condition     = can(cidrhost(var.virtual_network_address_space, 0)) && tonumber(split("/", var.virtual_network_address_space)[1]) <= 16
    error_message = "virtual_network_address_space must be a CIDR block of /16 or larger."
  }
}

variable "workload_namespaces" {
  type = map(object({
    owner                = string
    data_classification  = string
    service_account_name = optional(string, "workload")
    labels               = optional(map(string), {})
    resource_quota = optional(object({
      cpu_limit      = optional(string, "2000m")
      cpu_request    = optional(string, "1000m")
      memory_limit   = optional(string, "4Gi")
      memory_request = optional(string, "2Gi")
    }), {})
  }))
  default = {
    workload-a = {
      owner               = "platform-team"
      data_classification = "internal"
    }
  }
  description = <<DESCRIPTION
User workload namespaces created as AKS managed namespaces. Each namespace denies all ingress
and egress by default (CCC.K8S.CN06.AR01), has a resource quota (CCC.K8S.CN13.AR02), carries
ownership metadata (CCC.K8S.CN15.AR01) and gets a dedicated federated workload identity for
the named service account (CCC.K8S.CN03.AR01). The map key is the namespace name.

- `owner` - Owning team, recorded as an annotation.
- `data_classification` - Data classification, recorded as a label.
- `service_account_name` - Kubernetes service account federated to the workload identity.
- `labels` - Additional namespace labels.
- `resource_quota` - Aggregate CPU and memory requests and limits for the namespace.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for name in keys(var.workload_namespaces) : can(regex("^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$", name)) && !contains(["default", "kube-system", "kube-public", "kube-node-lease"], name)])
    error_message = "Workload namespace names must be DNS labels and must not be system or default namespaces."
  }
}
