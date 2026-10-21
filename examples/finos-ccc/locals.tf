locals {
  subscription_id = try(coalesce(try(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.resource_group_id).subscription_id, null), var.subscription_id), null)
  cluster_name    = coalesce(var.name, "aks-ccc-${random_string.name_suffix.result}")

  resource_group_id   = var.resource_group_id == null ? module.resource_group[0].resource_id : var.resource_group_id
  resource_group_name = var.resource_group_id == null ? module.resource_group[0].name : provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.resource_group_id).name

  # Network: created unless all existing subnet IDs are supplied (validated as all-or-none).
  create_network = var.subnet_id == null
  created_virtual_networks = local.create_network ? {
    cluster = {
      address_space = var.virtual_network_address_space
      subnets = {
        nodes = {
          address_prefix = cidrsubnet(var.virtual_network_address_space, 6, 0)
          delegation     = null
        }
        apiserver = {
          address_prefix = cidrsubnet(var.virtual_network_address_space, 12, 64)
          delegation     = "Microsoft.ContainerService/managedClusters"
        }
        endpoints = {
          address_prefix = cidrsubnet(var.virtual_network_address_space, 8, 5)
          delegation     = null
        }
      }
    }
    runner = {
      address_space = var.runner_virtual_network_address_space
      subnets = {
        runner = {
          address_prefix = cidrsubnet(var.runner_virtual_network_address_space, 2, 0)
          delegation     = null
        }
        endpoints = {
          address_prefix = cidrsubnet(var.runner_virtual_network_address_space, 2, 1)
          delegation     = null
        }
      }
    }
  } : {}
  created_subnets = merge({}, [
    for vnet_key, vnet in local.created_virtual_networks : {
      for subnet_key, subnet in vnet.subnets : "${vnet_key}-${subnet_key}" => subnet
    }
  ]...)

  node_subnet_id                                = local.create_network ? module.virtual_networks["cluster"].subnets["nodes"].resource_id : var.subnet_id
  api_server_subnet_id                          = local.create_network ? module.virtual_networks["cluster"].subnets["apiserver"].resource_id : var.api_server_subnet_id
  container_registry_private_endpoint_subnet_id = local.create_network ? module.virtual_networks["cluster"].subnets["endpoints"].resource_id : var.container_registry_private_endpoint_subnet_id
  private_endpoint_subnet_id                    = local.create_network ? module.virtual_networks["runner"].subnets["endpoints"].resource_id : var.key_vault_private_endpoint_subnet_id
  runner_subnet_id                              = local.create_network ? module.virtual_networks["runner"].subnets["runner"].resource_id : null
  virtual_network_id                            = local.create_network ? module.virtual_networks["cluster"].resource_id : provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.subnet_id).parent_id

  key_vault_dns_virtual_network_links = merge(
    var.key_vault_dns_virtual_network_links,
    local.create_network ? { runner-vnet = module.virtual_networks["runner"].resource_id } : {}
  )
  container_registry_private_dns_zone_id = var.container_registry_private_dns_zone_id == null ? module.container_registry_dns_zone[0].resource_id : var.container_registry_private_dns_zone_id

  control_plane_identity_id     = var.control_plane_identity_id == null ? module.cluster_identities["control-plane"].resource_id : var.control_plane_identity_id
  kubelet_identity_id           = var.kubelet_identity_id == null ? module.cluster_identities["kubelet"].resource_id : var.kubelet_identity_id
  private_dns_zone_id           = var.private_dns_zone_id == null ? module.api_dns_zone[0].resource_id : var.private_dns_zone_id
  key_vault_resource_id         = var.key_vault_resource_id == null ? module.key_vault[0].resource_id : var.key_vault_resource_id
  key_vault_key_id              = var.key_vault_key_id == null ? module.encryption_keys["kms"].id : var.key_vault_key_id
  kms_key_resource_id           = var.key_vault_key_id == null ? module.encryption_keys["kms"].resource_versionless_id : "${var.key_vault_resource_id}/keys/${split("/", var.key_vault_key_id)[4]}"
  disk_encryption_set_id        = var.disk_encryption_set_id == null ? module.disk_encryption_set[0].resource_id : var.disk_encryption_set_id
  control_plane_principal_id    = var.control_plane_identity_id == null ? module.cluster_identities["control-plane"].principal_id : data.azapi_resource.control_plane_identity[0].output.properties.principalId
  kubelet_principal_id          = var.kubelet_identity_id == null ? module.cluster_identities["kubelet"].principal_id : data.azapi_resource.kubelet_identity[0].output.properties.principalId
  create_key_vault_endpoint     = length(local.keys_to_create) > 0
  key_vault_private_dns_zone_id = var.key_vault_private_dns_zone_id == null ? try(module.key_vault_dns_zone[0].resource_id, null) : var.key_vault_private_dns_zone_id

  identities_to_create = {
    for name, existing_id in {
      control-plane = var.control_plane_identity_id
      kubelet       = var.kubelet_identity_id
    } : name => existing_id if existing_id == null
  }
  keys_to_create = merge(
    var.key_vault_key_id == null ? { kms = ["encrypt", "decrypt"] } : {},
    var.disk_encryption_set_id == null ? { disk = ["wrapKey", "unwrapKey"] } : {}
  )
  inspect_existing_vault = var.key_vault_resource_id != null && (var.control_plane_identity_id == null || var.key_vault_key_id == null || var.disk_encryption_set_id == null)

  # CCC.K8S.CN02.AR01: scoped Azure RBAC for Kubernetes. Without explicit assignments the
  # deployer receives cluster admin so the example remains operable.
  cluster_role_assignments = length(var.cluster_role_assignments) > 0 ? var.cluster_role_assignments : {
    deployer = {
      principal_id               = data.azapi_client_config.current.object_id
      role_definition_id_or_name = "Azure Kubernetes Service RBAC Cluster Admin"
      principal_type             = null
    }
  }

  # CCC.K8S.CN08.AR01: CSP-provided add-ons and managed features enabled on the cluster.
  # These values feed the module inputs, so the allowlist check cannot drift from them.
  enabled_cluster_features = {
    azure_key_vault_kms = true
    azure_policy        = true
    defender            = true
    image_cleaner       = true
    oms_agent           = true
    workload_identity   = true
  }
  enabled_addons                  = [for name, enabled in local.enabled_cluster_features : name if enabled]
  addon_profile_azure_policy      = { enabled = local.enabled_cluster_features.azure_policy }
  addon_profile_oms_agent_enabled = local.enabled_cluster_features.oms_agent

  # CCC.K8S.CN14.AR03: in-cluster security configuration changes by non-system identities.
  kubernetes_security_change_query = <<-KQL
    AKSAuditAdmin
    | where Verb in ("create", "update", "patch", "delete")
    | extend Resource = tostring(ObjectRef.resource), Username = tostring(User.username)
    | where Resource in ("clusterrolebindings", "clusterroles", "rolebindings", "roles", "mutatingwebhookconfigurations", "validatingwebhookconfigurations", "networkpolicies", "ciliumnetworkpolicies", "ciliumclusterwidenetworkpolicies")
    | where Username !startswith "system:"
    | project TimeGenerated, Verb, Resource, Namespace = tostring(ObjectRef.namespace), Name = tostring(ObjectRef.name), Username
  KQL

  # CCC.K8S.CN17.AR02: grants are scoped to the narrowest resource and created only for a
  # new principal or target. Existing-to-existing relationships remain externally owned.
  prerequisite_role_assignments = {
    for name, assignment in {
      control_plane_node_subnet = {
        create             = var.control_plane_identity_id == null || local.create_network
        scope              = local.node_subnet_id
        principal_id       = local.control_plane_principal_id
        role_definition_id = "4d97b98b-1d4f-4787-a291-c67834d212e7" # Network Contributor
      }
      control_plane_api_server_subnet = {
        create             = var.control_plane_identity_id == null || local.create_network
        scope              = local.api_server_subnet_id
        principal_id       = local.control_plane_principal_id
        role_definition_id = "4d97b98b-1d4f-4787-a291-c67834d212e7" # Network Contributor
      }
      control_plane_dns = {
        create             = var.control_plane_identity_id == null || var.private_dns_zone_id == null
        scope              = local.private_dns_zone_id
        principal_id       = local.control_plane_principal_id
        role_definition_id = "b12aa53e-6015-4669-85d0-8515ebb3ae7f" # Private DNS Zone Contributor
      }
      kubelet_operator = {
        create             = var.control_plane_identity_id == null || var.kubelet_identity_id == null
        scope              = local.kubelet_identity_id
        principal_id       = local.control_plane_principal_id
        role_definition_id = "f1a07417-d97a-45cb-824c-7a7467783830" # Managed Identity Operator
      }
      kms_crypto_user = {
        create             = var.control_plane_identity_id == null || var.key_vault_key_id == null
        scope              = local.kms_key_resource_id
        principal_id       = local.control_plane_principal_id
        role_definition_id = "12338af0-0e69-4776-bea7-57ae8d297424" # Key Vault Crypto User
      }
      kms_vault_contributor = {
        create             = var.control_plane_identity_id == null || var.key_vault_resource_id == null
        scope              = local.key_vault_resource_id
        principal_id       = local.control_plane_principal_id
        role_definition_id = "f25e0fa2-a7c8-4377-a976-54943a77a395" # Key Vault Contributor: AKS-managed private link
      }
      disk_encryption_set_reader = {
        create             = var.control_plane_identity_id == null || var.disk_encryption_set_id == null
        scope              = local.disk_encryption_set_id
        principal_id       = local.control_plane_principal_id
        role_definition_id = "acdd72a7-3385-48ef-bd42-f606fba81ae7" # Reader
      }
      disk_key_encryption_user = {
        create             = var.disk_encryption_set_id == null
        scope              = var.disk_encryption_set_id == null ? module.encryption_keys["disk"].resource_versionless_id : null
        principal_id       = var.disk_encryption_set_id == null ? data.azapi_resource.disk_encryption_set[0].output.identity.principalId : null
        role_definition_id = "e147488a-f6f5-4113-8e2d-b22465e65bf6" # Key Vault Crypto Service Encryption User
      }
    } : name => assignment if assignment.create
  }
}
