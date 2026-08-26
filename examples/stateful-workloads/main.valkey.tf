## Section to deploy the Valkey supporting resources only when var.valkey_enabled is set to true
######################################################################################################################

## Section to create the Azure Container Registry task that imports the Valkey image
######################################################################################################################
# The task identity has to be system assigned to work with private networking and
# `networkRuleBypassOptions` set to `AzureServices`.
resource "azapi_resource" "acr_task" {
  count = var.valkey_enabled ? 1 : 0

  location  = azapi_resource.acr.location
  name      = "image-import-task"
  parent_id = azapi_resource.acr.id
  type      = "Microsoft.ContainerRegistry/registries/tasks@2019-06-01-preview"
  body = {
    properties = {
      status = "Enabled"
      platform = {
        os = "Linux"
      }
      step = {
        type               = "EncodedTask"
        encodedTaskContent = base64encode(var.acr_task_content)
      }
    }
  }
  response_export_values = ["identity.principalId"]

  identity {
    type = "SystemAssigned"
  }
}

## Section to assign the role to the task identity
######################################################################################################################
resource "random_uuid" "acr_import" {
  count = var.valkey_enabled ? 1 : 0
}

resource "azapi_resource" "role_acr_import" {
  count = var.valkey_enabled ? 1 : 0

  name      = random_uuid.acr_import[0].result
  parent_id = azapi_resource.acr.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.acr_task[0].output.identity.principalId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/577a9874-89fd-4f24-9dbd-b5034d0ad23a"
    }
  }
  response_export_values = []
  # The task identity may not have replicated to Entra ID yet.
  retry = {
    error_message_regex  = ["PrincipalNotFound", "does not exist in the directory"]
    interval_seconds     = 10
    max_interval_seconds = 60
  }
}

## Section to run the Azure Container Registry task
######################################################################################################################
resource "azapi_resource_action" "acr_task_run" {
  count = var.valkey_enabled ? 1 : 0

  action      = "scheduleRun"
  method      = "POST"
  resource_id = azapi_resource.acr.id
  type        = azapi_resource.acr.type
  body = {
    type   = "TaskRunRequest"
    taskId = azapi_resource.acr_task[0].id
  }
  response_export_values = []

  depends_on = [azapi_resource.role_acr_import]

  lifecycle {
    replace_triggered_by = [azapi_resource.acr_task[0]]
  }
}

## Section to create the Azure Key Vault secret holding the Valkey password file
######################################################################################################################
resource "azapi_resource" "valkey_password_file" {
  count = var.valkey_enabled ? 1 : 0

  name                   = "valkey-password-file"
  parent_id              = azapi_resource.key_vault.id
  type                   = "Microsoft.KeyVault/vaults/secrets@2023-07-01"
  response_export_values = []
  sensitive_body = {
    properties = {
      value = <<-EOT
      requirepass  ${var.valkey_password}
      primaryauth  ${var.valkey_password}
      EOT
    }
  }

  depends_on = [azapi_resource.role_key_vault_administrator]
}

## Section to let the key vault secrets provider read the Valkey secret
######################################################################################################################
resource "random_uuid" "key_vault_secrets_user" {
  count = var.valkey_enabled ? 1 : 0
}

resource "azapi_resource" "role_key_vault_secrets_user" {
  count = var.valkey_enabled ? 1 : 0

  name      = random_uuid.key_vault_secrets_user[0].result
  parent_id = azapi_resource.key_vault.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = module.stateful_workloads.key_vault_secrets_provider_identity.objectId
      principalType    = "ServicePrincipal"
      roleDefinitionId = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6"
    }
  }
  response_export_values = []
  # The addon identity may not have replicated to Entra ID yet.
  retry = {
    error_message_regex  = ["PrincipalNotFound", "does not exist in the directory"]
    interval_seconds     = 10
    max_interval_seconds = 60
  }
}
