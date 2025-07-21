<!-- BEGIN_TF_DOCS -->
# Stateful Workloads example

This deploys the module for running ValKey workloads on AKS. For more information, see the [ValKey overview](https://learn.microsoft.com/en-us/azure/aks/valkey-overview).

```hcl
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# This ensures we have unique CAF compliant names for our resources.
######################################################################################################################

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4"
}

# Creating the resource group
######################################################################################################################
resource "azurerm_resource_group" "this" {
  location = coalesce(var.location, "eastus")
  name     = coalesce(var.resource_group_name, module.naming.resource_group.name_unique)
}


# Section to get the current client config
######################################################################################################################

data "azurerm_client_config" "current" {}


# Section to Create the Azure Key Vault 
######################################################################################################################

module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.9.1"

  location            = azurerm_resource_group.this.location
  name                = coalesce(var.keyvault_name, module.naming.key_vault.name_unique)
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  legacy_access_policies = {
    permissions = {
      object_id          = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "Set", "List"]
    }
  }
  legacy_access_policies_enabled = true
  network_acls                   = null
  public_network_access_enabled  = true
}

# ## Section to create the Azure Container Registry
# ######################################################################################################################
module "avm_res_containerregistry_registry" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.4.0"

  location            = azurerm_resource_group.this.location
  name                = coalesce(var.acr_registry_name, module.naming.container_registry.name_unique)
  resource_group_name = azurerm_resource_group.this.name
  admin_enabled       = false
  sku                 = "Premium"
}

## Section to create the Azure Container Registry task
######################################################################################################################
resource "azurerm_container_registry_task" "this" {
  container_registry_id = module.avm_res_containerregistry_registry.resource_id
  name                  = "image-import-task"

  encoded_step {
    task_content = base64encode(var.acr_task_content)
  }
  identity {
    type = "SystemAssigned" # Note this has to be a System Assigned Identity to work with private networking and `network_rule_bypass_option` set to `AzureServices`
  }
  platform {
    os = "Linux"
  }

  depends_on = [module.avm_res_containerregistry_registry]
}


## Section to assign the role to the task identity
######################################################################################################################
resource "azurerm_role_assignment" "container_registry_import_for_task" {
  principal_id         = azurerm_container_registry_task.this.identity[0].principal_id
  scope                = module.avm_res_containerregistry_registry.resource_id
  role_definition_name = "Container Registry Data Importer and Data Reader"
}

## Section to run the Azure Container Registry task
######################################################################################################################
resource "azurerm_container_registry_task_schedule_run_now" "this" {
  container_registry_task_id = azurerm_container_registry_task.this.id

  depends_on = [azurerm_role_assignment.container_registry_import_for_task]

  lifecycle {
    replace_triggered_by = [azurerm_container_registry_task.this]
  }
}

## Section to create the Azure Kubernetes Service
######################################################################################################################

module "stateful_workloads" {
  source = "../.."

  default_node_pool = {
    name                    = "systempool"
    node_count              = 3
    vm_size                 = "Standard_D2ds_v4"
    os_type                 = "Linux"
    auto_upgrade_channel    = "stable"
    node_os_upgrade_channel = "NodeImage"
    zones                   = [2, 3]

    addon_profile = {
      azure_key_vault_secrets_provider = {
        enabled = true
      }
    }
    upgrade_settings = {
      max_surge = "10%"
    }
  }
  location                  = azurerm_resource_group.this.location
  name                      = coalesce(var.cluster_name, module.naming.kubernetes_cluster.name_unique)
  resource_group_name       = azurerm_resource_group.this.name
  automatic_upgrade_channel = "stable"
  dns_prefix                = "statefulworkloads"
  key_vault_secrets_provider = {
    secret_rotation_enabled = true
  }
  local_account_disabled = false
  managed_identities = {
    system_assigned = true
  }
  network_profile = {
    network_plugin = "azure"
  }
  node_os_channel_upgrade   = "NodeImage"
  node_pools                = var.node_pools
  oidc_issuer_enabled       = true
  sku_tier                  = "Standard"
  workload_identity_enabled = true
}

## Section to assign the role to the kubelet identity
######################################################################################################################
resource "azurerm_role_assignment" "acr_role_assignment" {
  principal_id         = module.stateful_workloads.kubelet_identity_id
  scope                = module.avm_res_containerregistry_registry.resource_id
  role_definition_name = "AcrPull"

  depends_on = [module.avm_res_containerregistry_registry, module.stateful_workloads]
}

## Section to deploy valkey cluster only when var.valkey_enabled is set to true
######################################################################################################################
module "valkey" {
  source = "./valkey"
  count  = var.valkey_enabled ? 1 : 0

  key_vault_id    = module.avm_res_keyvault_vault.resource_id
  object_id       = module.stateful_workloads.key_vault_secrets_provider_object_id
  tenant_id       = data.azurerm_client_config.current.tenant_id
  valkey_password = var.valkey_password
}

## Section to deploy MongoDB cluster only when var.mongodb_enabled is set to true
######################################################################################################################
module "mongodb" {
  source = "./mongodb"
  count  = var.mongodb_enabled ? 1 : 0

  identity_name        = coalesce(var.identity_name, module.naming.user_assigned_identity.name_unique)
  key_vault_id         = module.avm_res_keyvault_vault.resource_id
  location             = azurerm_resource_group.this.location
  mongodb_kv_secrets   = var.mongodb_kv_secrets
  mongodb_namespace    = var.mongodb_namespace
  oidc_issuer_url      = module.stateful_workloads.oidc_issuer_url
  principal_id         = data.azurerm_client_config.current.object_id
  resource_group_name  = azurerm_resource_group.this.name
  service_account_name = var.service_account_name
  storage_account_name = coalesce(var.aks_mongodb_backup_storage_account_name, module.naming.storage_account.name_unique)
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 4.0.0, < 5.0.0)

## Resources

The following resources are used by this module:

- [azurerm_container_registry_task.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry_task) (resource)
- [azurerm_container_registry_task_schedule_run_now.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry_task_schedule_run_now) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.acr_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.container_registry_import_for_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_acr_registry_name"></a> [acr\_registry\_name](#input\_acr\_registry\_name)

Description: The name of the Azure Container Registry

Type: `string`

Default: `null`

### <a name="input_acr_task_content"></a> [acr\_task\_content](#input\_acr\_task\_content)

Description: The content of the ACR task

Type: `string`

Default: `"version: v1.1.0\nsteps:\n  - cmd: bash echo Waiting 60 seconds the propagation of the Container Registry Data Importer and Data Reader role\n  - cmd: bash sleep 60\n  - cmd: az login --identity\n  - cmd: az acr import --name $RegistryName --source acrforavmexamples.azurecr.io/valkey:latest --image valkey:latest\n"`

### <a name="input_aks_mongodb_backup_storage_account_name"></a> [aks\_mongodb\_backup\_storage\_account\_name](#input\_aks\_mongodb\_backup\_storage\_account\_name)

Description: The name of the backup storage account

Type: `string`

Default: `null`

### <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name)

Description: The name of the Kubernetes cluster

Type: `string`

Default: `null`

### <a name="input_identity_name"></a> [identity\_name](#input\_identity\_name)

Description: The name of the user assigner identity

Type: `string`

Default: `null`

### <a name="input_keyvault_name"></a> [keyvault\_name](#input\_keyvault\_name)

Description: The name of the Azure Key Vault

Type: `string`

Default: `null`

### <a name="input_location"></a> [location](#input\_location)

Description: The location of the resource group. Leaving this as null will select a random region

Type: `string`

Default: `"eastus"`

### <a name="input_mongodb_enabled"></a> [mongodb\_enabled](#input\_mongodb\_enabled)

Description: Enable MongoDB

Type: `bool`

Default: `false`

### <a name="input_mongodb_kv_secrets"></a> [mongodb\_kv\_secrets](#input\_mongodb\_kv\_secrets)

Description: Map of secret names to their values

Type: `map(string)`

Default: `null`

### <a name="input_mongodb_namespace"></a> [mongodb\_namespace](#input\_mongodb\_namespace)

Description: The name of the mongodb namespace to create

Type: `string`

Default: `null`

### <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools)

Description: Optional. The additional node pools for the Kubernetes cluster.

Type:

```hcl
map(object({
    name       = string
    vm_size    = string
    node_count = number
    zones      = optional(list(string))
    os_type    = string
    upgrade_settings = optional(object({
      drain_timeout_in_minutes      = optional(number)
      node_soak_duration_in_minutes = optional(number)
      max_surge                     = string
    }))
  }))
```

Default:

```json
{
  "valkey": {
    "name": "valkey",
    "node_count": 3,
    "os_type": "Linux",
    "upgrade_settings": {
      "max_surge": "10%"
    },
    "vm_size": "Standard_D2ds_v4",
    "zones": [
      2,
      3
    ]
  }
}
```

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The name of the resource group

Type: `string`

Default: `null`

### <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name)

Description: The name of the service account to create

Type: `string`

Default: `null`

### <a name="input_valkey_enabled"></a> [valkey\_enabled](#input\_valkey\_enabled)

Description: Enable Valkey

Type: `bool`

Default: `false`

### <a name="input_valkey_password"></a> [valkey\_password](#input\_valkey\_password)

Description: The password for the Valkey

Type: `string`

Default: `""`

## Outputs

The following outputs are exported:

### <a name="output_acr_registry_id"></a> [acr\_registry\_id](#output\_acr\_registry\_id)

Description: n/a

### <a name="output_acr_registry_name"></a> [acr\_registry\_name](#output\_acr\_registry\_name)

Description: n/a

### <a name="output_aks_cluster_name"></a> [aks\_cluster\_name](#output\_aks\_cluster\_name)

Description: n/a

### <a name="output_aks_kubelet_identity_id"></a> [aks\_kubelet\_identity\_id](#output\_aks\_kubelet\_identity\_id)

Description: n/a

### <a name="output_aks_nodepool_resource_ids"></a> [aks\_nodepool\_resource\_ids](#output\_aks\_nodepool\_resource\_ids)

Description: n/a

### <a name="output_aks_oidc_issuer_url"></a> [aks\_oidc\_issuer\_url](#output\_aks\_oidc\_issuer\_url)

Description: n/a

### <a name="output_identity_name"></a> [identity\_name](#output\_identity\_name)

Description: n/a

### <a name="output_identity_name_client_id"></a> [identity\_name\_client\_id](#output\_identity\_name\_client\_id)

Description: n/a

### <a name="output_identity_name_id"></a> [identity\_name\_id](#output\_identity\_name\_id)

Description: n/a

### <a name="output_identity_name_principal_id"></a> [identity\_name\_principal\_id](#output\_identity\_name\_principal\_id)

Description: n/a

### <a name="output_identity_name_tenant_id"></a> [identity\_name\_tenant\_id](#output\_identity\_name\_tenant\_id)

Description: n/a

### <a name="output_key_vault_id"></a> [key\_vault\_id](#output\_key\_vault\_id)

Description: n/a

### <a name="output_key_vault_uri"></a> [key\_vault\_uri](#output\_key\_vault\_uri)

Description: n/a

### <a name="output_storage_account_key"></a> [storage\_account\_key](#output\_storage\_account\_key)

Description: n/a

### <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name)

Description: n/a

## Modules

The following Modules are called:

### <a name="module_avm_res_containerregistry_registry"></a> [avm\_res\_containerregistry\_registry](#module\_avm\_res\_containerregistry\_registry)

Source: Azure/avm-res-containerregistry-registry/azurerm

Version: 0.4.0

### <a name="module_avm_res_keyvault_vault"></a> [avm\_res\_keyvault\_vault](#module\_avm\_res\_keyvault\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: 0.9.1

### <a name="module_mongodb"></a> [mongodb](#module\_mongodb)

Source: ./mongodb

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.4

### <a name="module_stateful_workloads"></a> [stateful\_workloads](#module\_stateful\_workloads)

Source: ../..

Version:

### <a name="module_valkey"></a> [valkey](#module\_valkey)

Source: ./valkey

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->