data "azapi_client_config" "current" {}

data "azapi_resource" "control_plane_identity" {
  count = var.control_plane_identity_id == null ? 0 : 1

  type                   = var.resource_types.managedidentity_user_assigned_identities
  resource_id            = var.control_plane_identity_id
  response_export_values = ["properties.principalId"]
}

data "azapi_resource" "existing_key_vault" {
  count = local.inspect_existing_vault ? 1 : 0

  type        = var.resource_types.keyvault_vaults
  resource_id = var.key_vault_resource_id
  response_export_values = [
    "properties.enableRbacAuthorization",
    "properties.enablePurgeProtection",
  ]

  lifecycle {
    postcondition {
      condition     = try(self.output.properties.enableRbacAuthorization, false) == true
      error_message = "Creating keys or new identity grants in an existing vault requires RBAC authorization. The example will not change its access model; use an RBAC vault or reuse all preconfigured encryption/identity inputs."
    }
    postcondition {
      condition = var.disk_encryption_set_id != null || (
        try(self.output.properties.enablePurgeProtection, false) == true && lower(self.location) == lower(var.location)
      )
      error_message = "A new DES requires a purge-protected vault in the cluster region. The example will not change the existing vault."
    }
  }
}

# CCC.K8S.CN17 [partial]: infrastructure identity separation, not workload grants.
module "cluster_identities" {
  source   = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version  = "0.5.3"
  for_each = local.identities_to_create

  name                = "id-ccc-${each.key}-${random_string.name_suffix.result}"
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags
  enable_telemetry    = false
}

# CCC.K8S.CN01 [supporting]: API-server VNet integration uses private.*.
module "api_dns_zone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"
  count   = var.private_dns_zone_id == null ? 1 : 0

  domain_name      = "ccc-${random_string.name_suffix.result}.private.${var.location}.azmk8s.io"
  parent_id        = var.resource_group_id
  tags             = var.tags
  enable_telemetry = false
  virtual_network_links = {
    cluster = {
      name                 = "cluster-vnet"
      virtual_network_id   = local.virtual_network_id
      registration_enabled = false
      tags                 = var.tags
    }
  }
}

# CCC.Core.CN02 / CCC.K8S.CN07 [partial]: private vault and recoverable keys.
# AzureServices bypass permits trusted Azure Disk Storage, not runner access.
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.12.0"
  count   = var.key_vault_resource_id == null ? 1 : 0

  name                            = "kv-ccc-${random_string.name_suffix.result}"
  resource_group_name             = local.resource_group_name
  location                        = var.location
  tenant_id                       = data.azapi_client_config.current.tenant_id
  sku_name                        = "standard"
  legacy_access_policies_enabled  = false
  purge_protection_enabled        = true
  soft_delete_retention_days      = 90
  public_network_access_enabled   = false
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
  tags             = var.tags
  enable_telemetry = false
}

module "key_vault_dns_zone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"
  count   = local.create_key_vault_endpoint && var.key_vault_private_dns_zone_id == null ? 1 : 0

  domain_name      = "privatelink.vaultcore.azure.net"
  parent_id        = var.resource_group_id
  tags             = var.tags
  enable_telemetry = false
  virtual_network_links = {
    for name, id in var.key_vault_dns_virtual_network_links : name => {
      name                 = name
      virtual_network_id   = id
      registration_enabled = false
      tags                 = var.tags
    }
  }
}

# Only explicitly requested NEW links are managed on a reused DNS zone.
module "key_vault_dns_links" {
  source   = "Azure/avm-res-network-privatednszone/azurerm//modules/private_dns_virtual_network_link"
  version  = "0.5.0"
  for_each = local.create_key_vault_endpoint && var.key_vault_private_dns_zone_id != null ? var.key_vault_dns_virtual_network_links : {}

  name               = each.key
  parent_id          = var.key_vault_private_dns_zone_id
  virtual_network_id = each.value
  tags               = var.tags
}

# A runner endpoint is separate from the private endpoint AKS creates for KMS.
# A standalone AVM module supports both created and reused vaults.
module "key_vault_endpoint" {
  source  = "Azure/avm-res-network-privateendpoint/azurerm"
  version = "0.2.0"
  count   = local.create_key_vault_endpoint ? 1 : 0

  name                           = "pe-ccc-vault-${random_string.name_suffix.result}"
  network_interface_name         = "nic-ccc-vault-${random_string.name_suffix.result}"
  resource_group_name            = local.resource_group_name
  location                       = var.location
  subnet_resource_id             = var.key_vault_private_endpoint_subnet_id
  private_connection_resource_id = local.key_vault_resource_id
  subresource_names              = ["vault"]
  private_dns_zone_group_name    = "default"
  private_dns_zone_resource_ids  = [local.key_vault_private_dns_zone_id]
  tags                           = var.tags
  enable_telemetry               = false
}

# The runner must already have effective Key Vault Crypto Officer permissions.
# AVM owns key CRUD; no create-only ARM action or temporary public access is used.
module "encryption_keys" {
  source   = "Azure/avm-res-keyvault-vault/azurerm//modules/key"
  version  = "0.12.0"
  for_each = local.keys_to_create

  key_vault_resource_id = local.key_vault_resource_id
  name                  = "aks-${each.key}-${random_string.name_suffix.result}"
  type                  = "RSA"
  size                  = 3072
  opts                  = each.value
  tags                  = var.tags

  depends_on = [
    data.azapi_resource.existing_key_vault,
    module.key_vault_endpoint,
    module.key_vault_dns_zone,
    module.key_vault_dns_links,
  ]
}

module "disk_encryption_set" {
  source  = "Azure/avm-res-compute-diskencryptionset/azurerm"
  version = "0.1.1"
  count   = var.disk_encryption_set_id == null ? 1 : 0

  name                              = "des-ccc-${random_string.name_suffix.result}"
  resource_group_name               = local.resource_group_name
  location                          = var.location
  key_vault_key_id                  = module.encryption_keys["disk"].id
  key_vault_resource_id             = local.key_vault_resource_id
  encryption_type                   = "EncryptionAtRestWithCustomerKey"
  auto_key_rotation_enabled         = false
  key_vault_role_assignment_enabled = false
  managed_identities = {
    system_assigned = true
  }
  tags             = var.tags
  enable_telemetry = false
}

# DES v0.1.1 exports no principal ID. Read it without adopting the resource.
data "azapi_resource" "disk_encryption_set" {
  count = var.disk_encryption_set_id == null ? 1 : 0

  type                   = var.resource_types.compute_disk_encryption_sets
  resource_id            = module.disk_encryption_set[0].resource_id
  response_export_values = ["identity.principalId"]
}

# CCC.K8S.CN17 [partial]: scoped grants only for new relationships.
module "prerequisite_role_assignments" {
  source  = "Azure/avm-res-authorization-roleassignment/azurerm"
  version = "0.3.1"

  enable_telemetry = false
  role_assignments_azure_resource_manager = {
    for name, assignment in local.prerequisite_role_assignments : name => {
      scope                            = assignment.scope
      principal_id                     = assignment.principal_id
      principal_type                   = "ServicePrincipal"
      role_definition_id               = "/subscriptions/${split("/", assignment.scope)[2]}/providers/Microsoft.Authorization/roleDefinitions/${assignment.role_definition_id}"
      skip_service_principal_aad_check = true
    }
  }

  depends_on = [data.azapi_resource.existing_key_vault]
}
