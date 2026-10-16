locals {
  cluster_name                  = coalesce(var.name, "aks-ccc-${random_string.name_suffix.result}")
  resource_group_name           = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.resource_group_id).name
  virtual_network_id            = provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", var.subnet_id).parent_id
  control_plane_identity_id     = var.control_plane_identity_id == null ? module.cluster_identities["control-plane"].resource_id : var.control_plane_identity_id
  kubelet_identity_id           = var.kubelet_identity_id == null ? module.cluster_identities["kubelet"].resource_id : var.kubelet_identity_id
  private_dns_zone_id           = var.private_dns_zone_id == null ? module.api_dns_zone[0].resource_id : var.private_dns_zone_id
  key_vault_resource_id         = var.key_vault_resource_id == null ? module.key_vault[0].resource_id : var.key_vault_resource_id
  key_vault_key_id              = var.key_vault_key_id == null ? module.encryption_keys["kms"].id : var.key_vault_key_id
  kms_key_resource_id           = var.key_vault_key_id == null ? module.encryption_keys["kms"].resource_versionless_id : "${var.key_vault_resource_id}/keys/${split("/", var.key_vault_key_id)[4]}"
  disk_encryption_set_id        = var.disk_encryption_set_id == null ? module.disk_encryption_set[0].resource_id : var.disk_encryption_set_id
  control_plane_principal_id    = var.control_plane_identity_id == null ? module.cluster_identities["control-plane"].principal_id : data.azapi_resource.control_plane_identity[0].output.properties.principalId
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

  # Manage a grant only for a new principal or target. Existing-to-existing
  # relationships (including existing DES key access) remain externally owned.
  prerequisite_role_assignments = {
    for name, assignment in {
      control_plane_network = {
        create             = var.control_plane_identity_id == null
        scope              = local.virtual_network_id
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
        role_definition_id = "14b46e9e-c2b7-41b4-b07b-48a6ebf60603" # Key Vault Crypto User
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
