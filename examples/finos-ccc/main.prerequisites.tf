data "azapi_client_config" "current" {}

data "azapi_resource" "control_plane_identity" {
  count = var.control_plane_identity_id == null ? 0 : 1

  resource_id            = var.control_plane_identity_id
  type                   = var.resource_types.managedidentity_user_assigned_identities
  response_export_values = ["properties.principalId"]
}

data "azapi_resource" "kubelet_identity" {
  count = var.kubelet_identity_id == null ? 0 : 1

  resource_id            = var.kubelet_identity_id
  type                   = var.resource_types.managedidentity_user_assigned_identities
  response_export_values = ["properties.principalId"]
}

data "azapi_resource" "existing_key_vault" {
  count = local.inspect_existing_vault ? 1 : 0

  resource_id = var.key_vault_resource_id
  type        = var.resource_types.keyvault_vaults
  response_export_values = [
    "properties.enableRbacAuthorization",
    "properties.enablePurgeProtection",
  ]

  lifecycle {
    postcondition {
      condition     = try(self.output.properties.enableRbacAuthorization, false) == true
      error_message = "New identity grants on keys in an existing vault require RBAC authorization. The example will not change its access model; use an RBAC vault or reuse all preconfigured encryption/identity inputs."
    }
    postcondition {
      condition = var.disk_encryption_set_id != null || (
        try(self.output.properties.enablePurgeProtection, false) == true && lower(self.location) == lower(var.location)
      )
      error_message = "A new DES requires a purge-protected vault in the cluster region. The example will not change the existing vault."
    }
  }
}

# CCC.K8S.CN17.AR01: distinct control-plane and kubelet identities.
module "cluster_identities" {
  source    = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version   = "0.5.3"
  providers = { modtm = modtm }
  for_each  = local.identities_to_create

  location            = var.location
  name                = "id-ccc-${each.key}-${random_string.name_suffix.result}"
  resource_group_name = local.resource_group_name
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags
}

# CCC.K8S.CN01.AR02: private API-server DNS; VNet integration uses private.<region>.azmk8s.io.
module "api_dns_zone" {
  source    = "Azure/avm-res-network-privatednszone/azurerm"
  version   = "0.5.0"
  providers = { modtm = modtm }
  count     = var.private_dns_zone_id == null ? 1 : 0

  domain_name      = "ccc-${random_string.name_suffix.result}.private.${var.location}.azmk8s.io"
  parent_id        = local.resource_group_id
  enable_telemetry = var.enable_telemetry
  tags             = var.tags
  virtual_network_links = {
    cluster = {
      name                 = "cluster-vnet"
      virtual_network_id   = local.virtual_network_id
      registration_enabled = false
      tags                 = var.tags
    }
  }
}

# CCC.Core.CN02 / CCC.K8S.CN07.AR01: private, purge-protected vault for KMS and disk keys.
# AzureServices bypass permits trusted Azure Disk Storage. No data-plane access is needed:
# keys are created through Azure Resource Manager below, so no identity, including the
# deployer, holds a Key Vault data-plane role beyond the scoped grants in locals.tf.
module "key_vault" {
  source    = "Azure/avm-res-keyvault-vault/azurerm"
  version   = "0.12.0"
  providers = { modtm = modtm }
  count     = var.key_vault_resource_id == null ? 1 : 0

  location                        = var.location
  name                            = "kv-ccc-${random_string.name_suffix.result}"
  resource_group_name             = local.resource_group_name
  tenant_id                       = data.azapi_client_config.current.tenant_id
  enable_telemetry                = var.enable_telemetry
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  legacy_access_policies_enabled  = false
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
  public_network_access_enabled = false
  purge_protection_enabled      = true
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  tags                          = var.tags
}

# Keys are created through the ARM control plane (Microsoft.KeyVault/vaults/keys), which
# works while the vault's public network access is disabled, so the default apply runs
# from any host. The AVM key submodule uses the data plane and would need a private
# endpoint and a runner inside the network.
# ARM PUT creates the first key version and returns an existing key unchanged. ARM does
# not support DELETE on keys (405), so an action is used instead of azapi_resource:
# destroying the created vault soft-deletes its keys; keys created in a reused vault are
# left in place on destroy.
resource "azapi_resource_action" "encryption_keys" {
  for_each = local.keys_to_create

  method      = "PUT"
  resource_id = "${local.key_vault_resource_id}/keys/${each.value.name}"
  type        = var.resource_types.keyvault_vaults_keys
  body = {
    tags = var.tags
    properties = {
      kty     = "RSA"
      keySize = 3072
      keyOps  = each.value.key_ops
      attributes = {
        enabled = true
      }
    }
  }
  response_export_values = ["properties.keyUri", "properties.keyUriWithVersion"]

  depends_on = [data.azapi_resource.existing_key_vault]
}

module "disk_encryption_set" {
  source    = "Azure/avm-res-compute-diskencryptionset/azurerm"
  version   = "0.1.1"
  providers = { modtm = modtm }
  count     = var.disk_encryption_set_id == null ? 1 : 0

  key_vault_key_id                  = azapi_resource_action.encryption_keys["disk"].output.properties.keyUriWithVersion
  key_vault_resource_id             = local.key_vault_resource_id
  location                          = var.location
  name                              = "des-ccc-${random_string.name_suffix.result}"
  resource_group_name               = local.resource_group_name
  auto_key_rotation_enabled         = false
  enable_telemetry                  = var.enable_telemetry
  encryption_type                   = "EncryptionAtRestWithCustomerKey"
  key_vault_role_assignment_enabled = false
  managed_identities = {
    system_assigned = true
  }
  tags = var.tags
}

# DES v0.1.1 exports no principal ID. Read it without adopting the resource.
data "azapi_resource" "disk_encryption_set" {
  count = var.disk_encryption_set_id == null ? 1 : 0

  resource_id            = module.disk_encryption_set[0].resource_id
  type                   = var.resource_types.compute_disk_encryption_sets
  response_export_values = ["identity.principalId"]
}

# CCC.K8S.CN17.AR02: least-privilege grants, created only for new relationships.
module "prerequisite_role_assignments" {
  source    = "Azure/avm-res-authorization-roleassignment/azurerm"
  version   = "0.3.1"
  providers = { modtm = modtm }

  enable_telemetry = var.enable_telemetry
  role_assignments_azure_resource_manager = {
    for name, assignment in local.prerequisite_role_assignments : name => {
      scope                            = assignment.scope
      principal_id                     = assignment.principal_id
      principal_type                   = "ServicePrincipal"
      role_definition_id               = "/subscriptions/${split("/", assignment.scope)[2]}/providers/Microsoft.Authorization/roleDefinitions/${assignment.role_definition_id}"
      skip_service_principal_aad_check = true
    }
  }

  # Key-scoped grants need the keys to exist first.
  depends_on = [
    data.azapi_resource.existing_key_vault,
    azapi_resource_action.encryption_keys,
  ]
}
