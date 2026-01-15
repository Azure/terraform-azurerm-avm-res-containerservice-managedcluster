# Upgrade Guide: AzureRM to AzAPI Provider Migration

This document outlines the breaking changes and migration steps required when upgrading from the AzureRM-based version of this module to the new AzAPI-based version.

## Overview

This major release migrates the underlying provider from `azurerm_kubernetes_cluster` to `azapi_resource` using the Azure Container Service API version `2025-10-01`. This change provides:

- Direct access to the latest Azure API features
- More granular control over cluster properties
- Alignment with Azure's native API structure

## Terraform Version Requirements

| Version   | Old (AzureRM)   | New (AzAPI) |
| --------- | --------------- | ----------- |
| Terraform | `>= 1.9, < 2.0` | `~> 1.12`   |

## Provider Requirements

The module now requires the AzAPI provider in addition to AzureRM:

```hcl
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.46.0, < 5.0.0"
    }
  }
}
```

## Breaking Changes

### Variables Removed

The following variables have been completely removed and are no longer supported:

| Variable                           | Reason                         | Migration Path                                  |
| ---------------------------------- | ------------------------------ | ----------------------------------------------- |
| `resource_group_name`              | Replaced with ARM resource ID  | Use `parent_id` with full resource group ID     |
| `sku_tier`                         | Consolidated into SKU object   | Use `sku.tier`                                  |
| `service_principal`                | Not supported in AzAPI version | Use managed identities via `managed_identities` |
| `kubelet_identity`                 | Managed automatically          | Remove from configuration                       |
| `http_application_routing_enabled` | Deprecated by Azure            | Use `web_app_routing_dns_zone_ids` instead      |
| `aci_connector_linux_subnet_name`  | Not implemented                | Remove from configuration                       |
| `edge_zone`                        | Not implemented                | Remove from configuration                       |
| `maintenance_window_node_os`       | Not implemented                | Use `maintenance_window_auto_upgrade`           |
| `open_service_mesh_enabled`        | Deprecated by Azure            | Use `service_mesh_profile` for Istio            |

### Variables Renamed

The following variables have been renamed to align with Azure API naming conventions:

| Old Name                                | New Name                           | Notes                                          |
| --------------------------------------- | ---------------------------------- | ---------------------------------------------- |
| `resource_group_name`                   | `parent_id`                        | Now requires full resource group resource ID   |
| `default_node_pool`                     | `default_agent_pool`               | Complete restructure (see below)               |
| `node_pools`                            | `agent_pools`                      | Complete restructure (see below)               |
| `role_based_access_control_enabled`     | `enable_role_based_access_control` | Same functionality                             |
| `local_account_disabled`                | `disable_local_accounts`           | Same functionality, default changed to `false` |
| `create_nodepools_before_destroy`       | `create_agentpools_before_destroy` | Same functionality                             |
| `kubernetes_cluster_timeouts`           | `cluster_timeouts`                 | Same functionality                             |
| `kubernetes_cluster_node_pool_timeouts` | `agentpool_timeouts`               | Same functionality                             |

### Variables Moved to Nested Objects

Several top-level variables have been consolidated into the `api_server_access_profile` object:

| Old Variable                          | New Location                                                   |
| ------------------------------------- | -------------------------------------------------------------- |
| `run_command_enabled`                 | `api_server_access_profile.run_command_enabled`                |
| `private_cluster_enabled`             | `api_server_access_profile.enable_private_cluster`             |
| `private_cluster_public_fqdn_enabled` | `api_server_access_profile.enable_private_cluster_public_fqdn` |
| `private_dns_zone_id`                 | `api_server_access_profile.private_dns_zone_id`                |

### api_server_access_profile Changes

| Old Attribute                                     | New Attribute                        |
| ------------------------------------------------- | ------------------------------------ |
| `virtual_network_integration_enabled`             | `enable_vnet_integration`            |
| (top-level) `run_command_enabled`                 | `run_command_enabled`                |
| (top-level) `private_cluster_enabled`             | `enable_private_cluster`             |
| (top-level) `private_cluster_public_fqdn_enabled` | `enable_private_cluster_public_fqdn` |
| (top-level) `private_dns_zone_id`                 | `private_dns_zone_id`                |

**Old Configuration:**

```hcl
private_cluster_enabled             = true
private_cluster_public_fqdn_enabled = true
private_dns_zone_id                 = "/subscriptions/.../privateDnsZones/..."
run_command_enabled                 = false

api_server_access_profile = {
  authorized_ip_ranges                = ["10.0.0.0/8"]
  virtual_network_integration_enabled = true
  subnet_id                           = "/subscriptions/.../subnets/..."
}
```

**New Configuration:**

```hcl
api_server_access_profile = {
  authorized_ip_ranges               = ["10.0.0.0/8"]
  enable_vnet_integration            = true
  subnet_id                          = "/subscriptions/.../subnets/..."
  enable_private_cluster             = true
  enable_private_cluster_public_fqdn = true
  private_dns_zone_id                = "/subscriptions/.../privateDnsZones/..."
  run_command_enabled                = false
}
```

### SKU Configuration Changes

The `sku_tier` variable has been replaced with a `sku` object:

**Old Configuration:**

```hcl
sku_tier = "Standard"
```

**New Configuration:**

```hcl
sku = {
  name = "Base"    # Options: Free, Base, Standard, Automatic
  tier = "Standard" # Options: Free, Standard
}
```

### Default Agent Pool / Node Pool Changes

The agent pool configuration has been significantly restructured to align with the Azure API:

#### Key Attribute Renames

| Old Attribute                  | New Attribute                               |
| ------------------------------ | ------------------------------------------- |
| `name`                         | `name` (unchanged)                          |
| `vm_size`                      | `vm_size` (unchanged)                       |
| `node_count`                   | `count_of`                                  |
| `auto_scaling_enabled`         | `enable_auto_scaling`                       |
| `host_encryption_enabled`      | `enable_encryption_at_host`                 |
| `node_public_ip_enabled`       | `enable_node_public_ip`                     |
| `fips_enabled`                 | `enable_fips`                               |
| `ultra_ssd_enabled`            | `enable_ultra_ssd`                          |
| `gpu_instance`                 | `gpu_instance_profile`                      |
| `zones`                        | `availability_zones`                        |
| `vnet_subnet_id`               | `vnet_subnet_id` (unchanged)                |
| `only_critical_addons_enabled` | Removed (use `mode = "System"` with taints) |
| `temporary_name_for_rotation`  | Removed                                     |

#### Kubelet Config Changes

| Old Attribute            | New Attribute             |
| ------------------------ | ------------------------- |
| `cpu_cfs_quota_enabled`  | `cpu_cfs_quota`           |
| `container_log_max_line` | `container_log_max_files` |
| `pod_max_pid`            | `pod_max_pids`            |

#### Linux OS Config Changes

The `sysctl_config` block has been renamed to `sysctls`, and the following attributes changed:

| Old Attribute                                                           | New Attribute                                               |
| ----------------------------------------------------------------------- | ----------------------------------------------------------- |
| `net_ipv4_ip_local_port_range_min` + `net_ipv4_ip_local_port_range_max` | `net_ipv4_ip_local_port_range` (string, e.g., "1024 65535") |
| `net_ipv4_tcp_keepalive_intvl`                                          | `net_ipv4_tcpkeepalive_intvl`                               |

#### New Agent Pool Features

The following new features are available in agent pools:

- `creation_data` - For creating from snapshots
- `gateway_profile` - Gateway agent pool configuration
- `gpu_profile` - GPU driver settings
- `local_dns_profile` - Per-node local DNS configuration
- `message_of_the_day` - Linux node MOTD
- `output_data_only` - Output body without creating resource
- `pod_ip_allocation_mode` - Pod IP allocation mode
- `power_state` - Agent pool power state
- `scale_set_eviction_policy` - Spot VM eviction policy
- `scale_set_priority` - VM priority (Regular/Spot)
- `security_profile` - Trusted launch settings
- `virtual_machines_profile` - VirtualMachines agent pool specs

### OMS Agent Changes

The `oms_agent` variable no longer includes `log_analytics_workspace_id`:

**Old Configuration:**

```hcl
oms_agent = {
  log_analytics_workspace_id      = "/subscriptions/.../workspaces/..."
  msi_auth_for_monitoring_enabled = true
}
```

**New Configuration:**

```hcl
log_analytics_workspace_id = "/subscriptions/.../workspaces/..."

oms_agent = {
  msi_auth_for_monitoring_enabled = true
}
```

### Service Mesh Profile Changes

The structure has been updated to match the Azure API:

**Old Configuration:**

```hcl
service_mesh_profile = {
  mode                             = "Istio"
  internal_ingress_gateway_enabled = true
  external_ingress_gateway_enabled = false
  revisions                        = ["asm-1-20"]
  certificate_authority = {
    key_vault_id           = "/subscriptions/.../vaults/..."
    root_cert_object_name  = "root-cert"
    cert_chain_object_name = "cert-chain"
    cert_object_name       = "cert"
    key_object_name        = "key"
  }
}
```

**New Configuration:**

```hcl
service_mesh_profile = {
  mode = "Istio"
  istio = {
    revisions = ["asm-1-20"]
    components = {
      ingressGateways = {
        enabled = true
        mode    = "Internal"  # or "External"
      }
      egressGateways = {
        enabled = false
      }
    }
    certificateAuthority = {
      plugin = {
        keyVaultId         = "/subscriptions/.../vaults/..."
        rootCertObjectName = "root-cert"
        certChainObjectName = "cert-chain"
        certObjectName     = "cert"
        keyObjectName      = "key"
      }
    }
  }
}
```

### Azure AD RBAC Changes

The `azure_active_directory_role_based_access_control` variable now has required fields:

**Old Configuration (optional fields):**

```hcl
azure_active_directory_role_based_access_control = {
  tenant_id              = null  # Optional, defaulted
  admin_group_object_ids = null  # Optional
  azure_rbac_enabled     = true
}
```

**New Configuration (required fields):**

```hcl
azure_active_directory_role_based_access_control = {
  tenant_id              = "00000000-0000-0000-0000-000000000000"  # Required
  admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"] # Required
  azure_rbac_enabled     = true
}
```

### Web App Routing Changes

The `web_app_routing_dns_zone_ids` type has changed:

**Old Configuration:**

```hcl
web_app_routing_dns_zone_ids = {
  "zone1" = ["/subscriptions/.../dnsZones/..."]
  "zone2" = ["/subscriptions/.../dnsZones/..."]
}
```

**New Configuration:**

```hcl
web_app_routing_dns_zone_ids = [
  "/subscriptions/.../dnsZones/...",
  "/subscriptions/.../dnsZones/..."
]
```

### Windows Profile Changes

New attribute added:

```hcl
windows_profile = {
  admin_username    = "azureuser"
  license           = "Windows_Server"
  csi_proxy_enabled = false  # New attribute
  gmsa = {
    root_domain = "example.com"
    dns_server  = "10.0.0.4"
  }
}

# New variable for password versioning
windows_profile_password_version = "v1"  # Required when using windows_profile_password
```

### HTTP Proxy Config Changes

The `no_proxy` type changed from `set(string)` to `list(string)`:

**Old Configuration:**

```hcl
http_proxy_config = {
  no_proxy = toset(["localhost", "127.0.0.1"])
}
```

**New Configuration:**

```hcl
http_proxy_config = {
  no_proxy = ["localhost", "127.0.0.1"]
}
```

## New Variables

The following new variables have been added:

| Variable                           | Type     | Description                                                 |
| ---------------------------------- | -------- | ----------------------------------------------------------- |
| `parent_id`                        | `string` | Resource group resource ID (replaces `resource_group_name`) |
| `advanced_networking`              | `object` | Advanced networking features (observability, security)      |
| `alert_email`                      | `string` | Email address for alerts                                    |
| `onboard_alerts`                   | `bool`   | Enable recommended alerts                                   |
| `onboard_monitoring`               | `bool`   | Enable monitoring resources                                 |
| `log_analytics_workspace_id`       | `string` | Log Analytics workspace for container logging               |
| `prometheus_workspace_id`          | `string` | Monitor workspace for managed Prometheus                    |
| `windows_profile_password_version` | `string` | Version of Windows admin password                           |
| `sku`                              | `object` | SKU configuration with name and tier                        |

### Advanced Networking Example

```hcl
advanced_networking = {
  enabled = true
  observability = {
    enabled = true
  }
  security = {
    enabled                   = true
    advanced_network_policies = "FQDN"  # Options: FQDN, HTTP, Kafka
  }
}
```

### Monitoring Configuration Example

```hcl
log_analytics_workspace_id = "/subscriptions/.../workspaces/my-workspace"
prometheus_workspace_id    = "/subscriptions/.../accounts/my-prometheus"
onboard_monitoring         = true
onboard_alerts             = true
alert_email                = "alerts@example.com"
```

## Output Changes

### Outputs Renamed

| Old Output              | New Output               |
| ----------------------- | ------------------------ |
| `nodepool_resource_ids` | `agentpool_resource_ids` |

### New Outputs

| Output                              | Description                                  |
| ----------------------------------- | -------------------------------------------- |
| `user_assigned_identity_client_ids` | Map of identity profile keys to clientIds    |
| `user_assigned_identity_object_ids` | Map of identity profile keys to objectIds    |
| `node_resource_group_name`          | Name of the auto-created node resource group |

### Outputs Removed

The following outputs have been removed:

| Output                                 |
| -------------------------------------- |
| `aci_connector_object_id`              |
| `ingress_app_object_id`                |
| `key_vault_secrets_provider_object_id` |
| `node_resource_group_id`               |
| `web_app_routing_object_id`            |

### kubeconfig Output Changes

The `kube_config` and `kube_admin_config` outputs now return raw YAML strings instead of structured objects:

**Old Usage:**

```hcl
provider "kubernetes" {
  host                   = module.aks.kube_config[0].host
  client_certificate     = base64decode(module.aks.kube_config[0].client_certificate)
  client_key             = base64decode(module.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config[0].cluster_ca_certificate)
}
```

**New Usage:**

```hcl
provider "kubernetes" {
  host                   = module.aks.host
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
  # Use exec plugin or token-based authentication
}
```

## State Migration

The module includes `moved` blocks to automatically migrate existing state from `azurerm_kubernetes_cluster.this` to `azapi_resource.this`. No manual state manipulation should be required.

```hcl
moved {
  from = azurerm_kubernetes_cluster.this
  to   = azapi_resource.this
}
```

## Migration Checklist

1. [ ] Update Terraform version to `~> 1.12`
2. [ ] Add AzAPI provider to your provider configuration
3. [ ] Replace `resource_group_name` with `parent_id` (full resource ID)
4. [ ] Replace `sku_tier` with `sku` object
5. [ ] Migrate `default_node_pool` to `default_agent_pool` structure
6. [ ] Migrate `node_pools` to `agent_pools` structure
7. [ ] Move private cluster settings into `api_server_access_profile`
8. [ ] Update `oms_agent` configuration (move workspace ID to separate variable)
9. [ ] Update `azure_active_directory_role_based_access_control` with required fields
10. [ ] Remove deprecated variables (`service_principal`, `kubelet_identity`, etc.)
11. [ ] Update any references to renamed outputs
12. [ ] Run `terraform plan` to verify migration
13. [ ] Apply changes

## Example Migration

### Before (AzureRM)

```hcl
module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.3.x"

  name                = "my-aks-cluster"
  resource_group_name = "my-resource-group"
  location            = "eastus"

  sku_tier = "Standard"

  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = true
  private_dns_zone_id                 = "/subscriptions/.../privateDnsZones/..."
  run_command_enabled                 = false

  role_based_access_control_enabled = true
  local_account_disabled            = true

  default_node_pool = {
    name                   = "system"
    vm_size                = "Standard_D4s_v3"
    node_count             = 3
    auto_scaling_enabled   = true
    min_count              = 1
    max_count              = 5
    zones                  = ["1", "2", "3"]
    vnet_subnet_id         = "/subscriptions/.../subnets/..."
  }

  oms_agent = {
    log_analytics_workspace_id      = "/subscriptions/.../workspaces/..."
    msi_auth_for_monitoring_enabled = true
  }

  managed_identities = {
    system_assigned = true
  }
}
```

### After (AzAPI)

```hcl
module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.4.x"

  name      = "my-aks-cluster"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-resource-group"
  location  = "eastus"

  sku = {
    name = "Base"
    tier = "Standard"
  }

  api_server_access_profile = {
    enable_private_cluster             = true
    enable_private_cluster_public_fqdn = true
    private_dns_zone_id                = "/subscriptions/.../privateDnsZones/..."
    run_command_enabled                = false
  }

  enable_role_based_access_control = true
  disable_local_accounts           = true

  azure_active_directory_role_based_access_control = {
    tenant_id              = "00000000-0000-0000-0000-000000000000"
    admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]
    azure_rbac_enabled     = true
  }

  default_agent_pool = {
    name                = "system"
    vm_size             = "Standard_D4s_v3"
    count_of            = 3
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 5
    availability_zones  = ["1", "2", "3"]
    vnet_subnet_id      = "/subscriptions/.../subnets/..."
  }

  log_analytics_workspace_id = "/subscriptions/.../workspaces/..."

  oms_agent = {
    msi_auth_for_monitoring_enabled = true
  }

  managed_identities = {
    system_assigned = true
  }
}
```

## Getting Help

If you encounter issues during migration:

1. Review the [Azure AKS documentation](https://docs.microsoft.com/azure/aks/)
2. Check the [AzAPI provider documentation](https://registry.terraform.io/providers/Azure/azapi/latest/docs)
3. Open an issue on the [module repository](https://github.com/Azure/terraform-azurerm-avm-res-containerservice-managedcluster/issues)
