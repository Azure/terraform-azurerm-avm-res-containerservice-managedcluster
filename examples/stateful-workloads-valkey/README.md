<!-- BEGIN_TF_DOCS -->
# Stateful Workloads example

This deploys the module for running ValKey workloads on AKS. For more information, see the [ValKey overview](https://learn.microsoft.com/en-us/azure/aks/valkey-overview).

```hcl
terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
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


## Section to provide a random Azure region for the resource group, This allows us to randomize the region for the resource group.
######################################################################################################################

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
}


## This allows us to randomize the region for the resource group.
######################################################################################################################

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}


# This ensures we have unique CAF compliant names for our resources.
######################################################################################################################

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# Creating the resource group
######################################################################################################################
resource "azurerm_resource_group" "this" {
  location = coalesce(var.location, module.regions.regions[random_integer.region_index.result].name)
  name     = coalesce(var.resource_group_name, module.naming.resource_group.name_unique)
}


# Section to get the current client config
######################################################################################################################

data "azurerm_client_config" "current" {}


# Section to Create the Azure Key Vault 
######################################################################################################################

module "avm_res_keyvault_vault" {
  source                         = "Azure/avm-res-keyvault-vault/azurerm"
  version                        = "0.9.1"
  location                       = azurerm_resource_group.this.location
  tenant_id                      = data.azurerm_client_config.current.tenant_id
  resource_group_name            = azurerm_resource_group.this.name
  name                           = module.naming.key_vault.name_unique
  legacy_access_policies_enabled = true
  public_network_access_enabled  = true
  network_acls                   = null
  legacy_access_policies = {
    permissions = {
      object_id          = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "Set", "List"]
    }
  }
}

resource "azurerm_key_vault_access_policy" "for_kv_secret_provider" {
  key_vault_id = module.avm_res_keyvault_vault.resource_id
  object_id    = module.default.key_vault_secrets_provider_object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  secret_permissions = [
    "Get",
    "List",
    "Set",
  ]
}


# ## Section to create the Azure Container Registry
# ######################################################################################################################
module "avm_res_containerregistry_registry" {
  source              = "Azure/avm-res-containerregistry-registry/azurerm"
  version             = "0.4.0"
  resource_group_name = azurerm_resource_group.this.name
  name                = module.naming.container_registry.name_unique
  location            = azurerm_resource_group.this.location
  sku                 = "Premium"
  admin_enabled       = true
}

## Section to create the Azure Container Registry task
######################################################################################################################
resource "azurerm_container_registry_task" "this" {
  container_registry_id = module.avm_res_containerregistry_registry.resource_id
  name                  = "image-import-task"

  encoded_step {
    task_content = base64encode(<<-EOF
version: v1.1.0
steps: 
  - cmd: az login --identity
  - cmd: az acr import --name $RegistryName --source docker.io/valkey/valkey:latest --image valkey:latest
EOF
    )
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

  depends_on = [azurerm_container_registry_task.this, module.avm_res_containerregistry_registry]
}

## Section to run the Azure Container Registry task
######################################################################################################################
resource "azurerm_container_registry_task_schedule_run_now" "this" {
  container_registry_task_id = azurerm_container_registry_task.this.id

  depends_on = [azurerm_container_registry_task.this, azurerm_role_assignment.container_registry_import_for_task]

  lifecycle {
    replace_triggered_by = [azurerm_container_registry_task.this]
  }
}

## Section to create the Azure Kubernetes Service
######################################################################################################################
module "default" {
  source                    = "../.."
  name                      = coalesce(var.cluster_name, module.naming.kubernetes_cluster.name_unique)
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  sku_tier                  = "Standard"
  local_account_disabled    = false
  node_os_channel_upgrade   = "NodeImage"
  automatic_upgrade_channel = "stable"

  default_node_pool = {
    name                    = "systempool"
    node_count              = 3
    vm_size                 = "Standard_D2ds_v4"
    os_type                 = "Linux"
    auto_upgrade_channel    = "stable"
    node_os_upgrade_channel = "NodeImage"
    zones                   = [1, 2, 3]

    addon_profile = {
      azure_key_vault_secrets_provider = {
        enabled = true
      }
    }
    upgrade_settings = {
      max_surge = "10%"
    }
  }

  node_pools                = var.node_pools
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  network_profile = {
    network_plugin = "azure"
  }
  key_vault_secrets_provider = {
    secret_rotation_enabled = true
  }
}

## Section to assign the role to the kubelet identity
######################################################################################################################
resource "azurerm_role_assignment" "acr_role_assignment" {
  principal_id         = module.default.kubelet_identity_id
  scope                = module.avm_res_containerregistry_registry.resource_id
  role_definition_name = "AcrPull"

  depends_on = [module.avm_res_containerregistry_registry, module.default]
}

resource "random_password" "requirepass" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}

resource "random_password" "primaryauth" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}

resource "local_file" "valkey_password_file" {
  filename = "/tmp/valkey-password-file.conf"
  content  = <<EOF
requirepass  ${coalesce(var.valkey_password, random_password.requirepass.result)}
primaryauth  ${coalesce(var.valkey_password, random_password.primaryauth.result)}
EOF
}

resource "azurerm_key_vault_secret" "valkey_password_file" {
  key_vault_id = module.avm_res_keyvault_vault.resource_id
  name         = "valkey-password-file"
  value        = local_file.valkey_password_file.content
}

resource "null_resource" "cleanup" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "rm /tmp/valkey-password-file.conf"
  }
}

```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9.2)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 4.0.0, < 5.0.0)

- <a name="requirement_local"></a> [local](#requirement\_local) (~> 2.5)

- <a name="requirement_null"></a> [null](#requirement\_null) (~> 3.2)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_container_registry_task.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry_task) (resource)
- [azurerm_container_registry_task_schedule_run_now.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry_task_schedule_run_now) (resource)
- [azurerm_key_vault_access_policy.for_kv_secret_provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) (resource)
- [azurerm_key_vault_secret.valkey_password_file](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.acr_role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.container_registry_import_for_task](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [local_file.valkey_password_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) (resource)
- [null_resource.cleanup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_password.primaryauth](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [random_password.requirepass](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name)

Description: The name of the Kubernetes cluster

Type: `string`

Default: `null`

### <a name="input_location"></a> [location](#input\_location)

Description: The location of the resource group. Leaving this as null will select a random region

Type: `string`

Default: `"centralus"`

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
  }))
```

Default:

```json
{
  "valkey": {
    "name": "valkey",
    "node_count": 3,
    "os_type": "Linux",
    "vm_size": "Standard_D2ds_v4",
    "zones": [
      1,
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

### <a name="input_valkey_password"></a> [valkey\_password](#input\_valkey\_password)

Description: The password for the Valkey

Type: `string`

Default: `""`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_avm_res_containerregistry_registry"></a> [avm\_res\_containerregistry\_registry](#module\_avm\_res\_containerregistry\_registry)

Source: Azure/avm-res-containerregistry-registry/azurerm

Version: 0.4.0

### <a name="module_avm_res_keyvault_vault"></a> [avm\_res\_keyvault\_vault](#module\_avm\_res\_keyvault\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: 0.9.1

### <a name="module_default"></a> [default](#module\_default)

Source: ../..

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: ~> 0.1

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->