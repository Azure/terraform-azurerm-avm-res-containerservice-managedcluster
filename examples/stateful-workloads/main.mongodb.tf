## Section to deploy the MongoDB supporting resources only when var.mongodb_enabled is set to true
######################################################################################################################

## Section to create the storage account for storing mongodb backups
######################################################################################################################
resource "azapi_resource" "mongodb_storage" {
  count = var.mongodb_enabled ? 1 : 0

  location  = azapi_resource.rg.location
  name      = coalesce(var.aks_mongodb_backup_storage_account_name, module.naming.storage_account.name_unique)
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_ZRS"
    }
    properties = {
      allowBlobPublicAccess    = false
      allowSharedKeyAccess     = true
      minimumTlsVersion        = "TLS1_2"
      publicNetworkAccess      = "Enabled"
      supportsHttpsTrafficOnly = true
    }
  }
  response_export_values = []
}

resource "azapi_resource" "mongodb_backup_container" {
  count = var.mongodb_enabled ? 1 : 0

  name      = "backups"
  parent_id = "${azapi_resource.mongodb_storage[0].id}/blobServices/default"
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01"
  body = {
    properties = {}
  }
  response_export_values = []
}

# The storage account key is only retrievable through the listKeys action.
data "azapi_resource_action" "mongodb_storage_keys" {
  count = var.mongodb_enabled ? 1 : 0

  action                 = "listKeys"
  method                 = "POST"
  resource_id            = azapi_resource.mongodb_storage[0].id
  type                   = azapi_resource.mongodb_storage[0].type
  response_export_values = ["keys"]
}

## Section to create the user-assigned identity
######################################################################################################################
resource "azapi_resource" "mongodb_identity" {
  count = var.mongodb_enabled ? 1 : 0

  location               = azapi_resource.rg.location
  name                   = coalesce(var.identity_name, module.naming.user_assigned_identity.name_unique)
  parent_id              = azapi_resource.rg.id
  type                   = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  response_export_values = ["properties.clientId", "properties.principalId", "properties.tenantId"]
}

## Section to create the Azure Key Vault secrets for MongoDB
######################################################################################################################
locals {
  mongodb_kv_secrets = var.mongodb_enabled ? merge(
    {
      "AZURE-STORAGE-ACCOUNT-KEY"  = data.azapi_resource_action.mongodb_storage_keys[0].output.keys[0].value
      "AZURE-STORAGE-ACCOUNT-NAME" = azapi_resource.mongodb_storage[0].name
    },
    var.mongodb_kv_secrets == null ? {} : var.mongodb_kv_secrets
  ) : {}
}

resource "azapi_resource" "mongodb_secrets" {
  for_each = local.mongodb_kv_secrets

  name                   = each.key
  parent_id              = azapi_resource.key_vault.id
  type                   = "Microsoft.KeyVault/vaults/secrets@2023-07-01"
  response_export_values = []
  sensitive_body = {
    properties = {
      value = each.value
    }
  }

  depends_on = [azapi_resource.role_key_vault_administrator]
}

## Section to create the federated identity credential for the external secrets operator to access the secret
######################################################################################################################
resource "azapi_resource" "mongodb_federated_credential" {
  count = var.mongodb_enabled ? 1 : 0

  name      = "external-secret-operator"
  parent_id = azapi_resource.mongodb_identity[0].id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31"
  body = {
    properties = {
      audiences = ["api://AzureADTokenExchange"]
      issuer    = module.stateful_workloads.oidc_issuer_profile_issuer_url
      subject   = "system:serviceaccount:${var.mongodb_namespace}:${var.service_account_name}"
    }
  }
  response_export_values = []
}

## Section to let the user-assigned identity read the secrets in the key vault
######################################################################################################################
resource "random_uuid" "mongodb_key_vault_secrets_user" {
  count = var.mongodb_enabled ? 1 : 0
}

resource "azapi_resource" "role_mongodb_key_vault_secrets_user" {
  count = var.mongodb_enabled ? 1 : 0

  name      = random_uuid.mongodb_key_vault_secrets_user[0].result
  parent_id = azapi_resource.key_vault.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.mongodb_identity[0].output.properties.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6"
    }
  }
  response_export_values = []
  # The user-assigned identity may not have replicated to Entra ID yet.
  retry = {
    error_message_regex  = ["PrincipalNotFound", "does not exist in the directory"]
    interval_seconds     = 10
    max_interval_seconds = 60
  }
}
