provider "azapi" {
  subscription_id = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.resource_group_id).subscription_id
}

# Published prerequisite AVMs require AzureRM; the AKS module remains AzAPI.
provider "azurerm" {
  subscription_id                 = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.resource_group_id).subscription_id
  resource_provider_registrations = "none"

  features {
    key_vault {
      purge_soft_delete_on_destroy       = false
      purge_soft_deleted_keys_on_destroy = false
      recover_soft_deleted_key_vaults    = false
      recover_soft_deleted_keys          = false
    }
  }
}

resource "random_string" "name_suffix" {
  length  = 8
  special = false
  upper   = false
}

# CCC annotations describe supporting configuration, not assessed compliance.
# Prerequisites and remaining controls are documented in _header.md.
module "aks" {
  source = "../.."

  # Controls: CCC.Core.CN06, CCC.K8S.CN09, CCC.K8S.CN15 [coverage: partial]
  # Region approval, version support/patch evidence and tag/label enforcement
  # are external. These inputs identify the deployment environment only.
  name                = local.cluster_name
  location            = var.location
  parent_id           = var.resource_group_id
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags
  enable_telemetry    = false
  resource_types      = var.resource_types.containerservice_managed_clusters
  retry               = var.retry
  timeouts            = var.timeouts
  ignore_body_changes = var.ignore_body_changes.containerservice_managed_clusters

  sku = {
    name = "Base"
    tier = "Free"
  }

  # Controls: CCC.K8S.CN17 [coverage: partial]
  # Separate created/reused identities; prerequisite grants are narrowly scoped.
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [local.control_plane_identity_id]
  }

  identity_profile = {
    kubeletidentity = {
      resource_id = local.kubelet_identity_id
    }
  }

  # Controls: CCC.K8S.CN02, CCC.K8S.CN16 [coverage: partial]
  # Application Roles/Bindings, MFA and revocation are external; local accounts
  # are not disabled by this example. Admin groups are not workload least privilege.
  enable_rbac = true
  aad_profile = {
    managed                = true
    enable_azure_rbac      = false
    admin_group_object_ids = var.cluster_admin_group_object_ids
  }

  # Controls: CCC.K8S.CN01, CCC.Core.CN05 [coverage: partial]
  # Restrict connected private networks with approved NSGs/routes/DNS. Public
  # network access and Run Command are not explicitly disabled by this example.
  api_server_access_profile = {
    enable_private_cluster             = true
    enable_private_cluster_public_fqdn = false
    enable_vnet_integration            = true
    private_dns_zone                   = local.private_dns_zone_id
    subnet_id                          = var.api_server_subnet_id
  }

  # Controls: CCC.K8S.CN03 [coverage: supporting]
  # Dedicated workload identities/federated credentials and static-key prevention
  # must be configured separately; enabling OIDC alone does not satisfy the control.
  oidc_issuer_profile = {
    enabled = true
  }

  # Controls: CCC.Core.CN02, CCC.K8S.CN07 [coverage: partial]
  # DES covers node disks; private KMS covers Kubernetes secrets at rest, not
  # workload secret authorization/delivery or every persistent volume.
  disk_encryption_set_id = local.disk_encryption_set_id
  security_profile = {
    workload_identity = {
      enabled = true
    }
    azure_key_vault_kms = {
      enabled                  = true
      key_id                   = local.key_vault_key_id
      key_vault_network_access = "Private"
      key_vault_resource_id    = local.key_vault_resource_id
    }
  }

  # Controls: CCC.K8S.CN12, CCC.K8S.CN18 [coverage: partial]
  # No public node IPs; kubelet/IMDS/SSH restrictions and boot attestation are
  # not established by these settings. Sizing is demonstration capacity only.
  default_agent_pool = {
    name                  = "systempool"
    vm_size               = "Standard_D4s_v5"
    count_of              = 2
    max_pods              = 30
    vnet_subnet_id        = var.subnet_id
    os_sku                = "Ubuntu"
    os_disk_type          = "Managed"
    enable_node_public_ip = false
    availability_zones    = ["1", "2", "3"]
  }

  # Controls: CCC.K8S.CN06 [coverage: supporting]
  # Cilium needs actual default-deny/approved-allow NetworkPolicies; the existing
  # subnet must already have a UDR/firewall egress path that supports AKS.
  network_profile = {
    load_balancer_sku   = "standard"
    outbound_type       = "userDefinedRouting"
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_dataplane   = "cilium"
    network_policy      = "cilium"
    pod_cidr            = "172.18.0.0/16"
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  # Controls: CCC.K8S.CN08 [coverage: partial]
  # Disabled Azure Policy is not an approved add-on inventory. CN04/CN05/CN11
  # image trust, restricted workload and admission enforcement are not installed.
  addon_profile_azure_policy = {
    enabled = false
  }

  # Node SSH, linux_profile and SSH keys intentionally left at AVM defaults.
  # No additional pools: all nodes use the hardened default pool above.
  # CN10/CN13/CN14 PVC policy, workload bounds and audit/alerts remain external.

  depends_on = [
    module.prerequisite_role_assignments,
    module.api_dns_zone,
  ]
}
