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

| Variable                              | Reason                                    | Migration Path                                                              |
| ------------------------------------- | ----------------------------------------- | --------------------------------------------------------------------------- |
| `resource_group_name`                 | Replaced with ARM resource ID             | Use `parent_id` with full resource group ID                                 |
| `sku_tier`                            | Consolidated into SKU object              | Use `sku.tier`                                                              |
| `service_principal`                   | Replaced with `service_principal_profile` | Use `service_principal_profile` with `client_id` and `secret`               |
| `kubelet_identity`                    | Replaced with `identity_profile`          | Use `identity_profile` with `kubeletidentity` key                           |
| `http_application_routing_enabled`    | Deprecated by Azure                       | Use `ingress_profile.web_app_routing` instead                               |
| `aci_connector_linux_subnet_name`     | Not implemented                           | Remove from configuration                                                   |
| `edge_zone`                           | Replaced with `extended_location`         | Use `extended_location` with `name` and `type`                              |
| `maintenance_window`                  | Replaced with unified configuration       | Use `maintenanceconfiguration` map variable                                 |
| `maintenance_window_auto_upgrade`     | Replaced with unified configuration       | Use `maintenanceconfiguration` map variable                                 |
| `maintenance_window_node_os`          | Replaced with unified configuration       | Use `maintenanceconfiguration` map variable                                 |
| `open_service_mesh_enabled`           | Deprecated by Azure                       | Use `service_mesh_profile` for Istio                                        |
| `cluster_suffix`                      | No longer needed                          | Remove from configuration                                                   |
| `cost_analysis_enabled`               | Moved to nested object                    | Use `metrics_profile.cost_analysis.enabled`                                 |
| `default_nginx_controller`            | Moved to nested object                    | Use `ingress_profile.web_app_routing.nginx.default_ingress_controller_type` |
| `defender_log_analytics_workspace_id` | Moved to nested object                    | Use `security_profile.defender.log_analytics_workspace_resource_id`         |
| `dns_prefix_private_cluster`          | Replaced with `fqdn_subdomain`            | Use `fqdn_subdomain`                                                        |
| `image_cleaner_enabled`               | Moved to nested object                    | Use `security_profile.image_cleaner.enabled`                                |
| `image_cleaner_interval_hours`        | Moved to nested object                    | Use `security_profile.image_cleaner.interval_hours`                         |
| `monitor_metrics`                     | Replaced with `azure_monitor_profile`     | Use `azure_monitor_profile.metrics`                                         |
| `node_os_channel_upgrade`             | Moved to nested object                    | Use `auto_upgrade_profile.node_os_upgrade_channel`                          |
| `node_resource_group_name`            | Renamed                                   | Use `node_resource_group`                                                   |
| `oidc_issuer_enabled`                 | Moved to nested object                    | Use `oidc_issuer_profile.enabled`                                           |
| `private_cluster_enabled`             | Moved to nested object                    | Use `api_server_access_profile.enable_private_cluster`                      |
| `private_cluster_public_fqdn_enabled` | Moved to nested object                    | Use `api_server_access_profile.enable_private_cluster_public_fqdn`          |
| `private_dns_zone_id`                 | Moved to nested object                    | Use `api_server_access_profile.private_dns_zone`                            |
| `run_command_enabled`                 | Moved to nested object (inverted logic)   | Use `api_server_access_profile.disable_run_command`                         |
| `upgrade_override`                    | Replaced with `upgrade_settings`          | Use `upgrade_settings.override_settings`                                    |
| `workload_identity_enabled`           | Moved to nested object                    | Use `security_profile.workload_identity.enabled`                            |

### Variables Renamed

The following variables have been renamed to align with Azure API naming conventions:

| Old Name                                           | New Name                                                | Notes                                        |
| -------------------------------------------------- | ------------------------------------------------------- | -------------------------------------------- |
| `resource_group_name`                              | `parent_id`                                             | Now requires full resource group resource ID |
| `default_node_pool`                                | `default_agent_pool`                                    | Complete restructure (see below)             |
| `node_pools`                                       | `agent_pools`                                           | Complete restructure (see below)             |
| `role_based_access_control_enabled`                | `enable_rbac`                                           | Same functionality                           |
| `local_account_disabled`                           | `disable_local_accounts`                                | Same functionality                           |
| `create_nodepools_before_destroy`                  | `create_agentpools_before_destroy`                      | Same functionality                           |
| `kubernetes_cluster_timeouts`                      | `cluster_timeouts`                                      | Same functionality                           |
| `kubernetes_cluster_node_pool_timeouts`            | `agentpool_timeouts`                                    | Same functionality                           |
| `azure_active_directory_role_based_access_control` | `aad_profile`                                           | Restructured (see below)                     |
| `azure_policy_enabled`                             | `addon_profile_azure_policy.enabled`                    | Moved to addon profile object                |
| `confidential_computing`                           | `addon_profile_confidential_computing`                  | Restructured as addon profile                |
| `ingress_application_gateway`                      | `addon_profile_ingress_application_gateway`             | Restructured as addon profile                |
| `key_vault_secrets_provider`                       | `addon_profile_key_vault_secrets_provider`              | Restructured as addon profile                |
| `oms_agent`                                        | `addon_profile_oms_agent`                               | Restructured as addon profile                |
| `web_app_routing_dns_zone_ids`                     | `ingress_profile.web_app_routing.dns_zone_resource_ids` | Now a list instead of map                    |
| `workload_autoscaler_profile`                      | `workload_auto_scaler_profile`                          | Restructured with nested objects             |
| `automatic_upgrade_channel`                        | `auto_upgrade_profile.upgrade_channel`                  | Moved to nested object                       |

### AAD Profile Changes

The `azure_active_directory_role_based_access_control` variable has been renamed to `aad_profile` with restructured attributes:

**Old Configuration:**

```hcl
azure_active_directory_role_based_access_control = {
  tenant_id              = "00000000-0000-0000-0000-000000000000"
  admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]
  azure_rbac_enabled     = true
}
```

**New Configuration:**

```hcl
aad_profile = {
  tenant_id              = "00000000-0000-0000-0000-000000000000"
  admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]
  enable_azure_rbac      = true
  managed                = true
}
```

| Old Attribute        | New Attribute       |
| -------------------- | ------------------- |
| `azure_rbac_enabled` | `enable_azure_rbac` |
| N/A                  | `managed`           |
| N/A                  | `client_app_id`     |
| N/A                  | `server_app_id`     |
| N/A                  | `server_app_secret` |

### api_server_access_profile Changes

| Old Attribute / Variable                          | New Attribute                        |
| ------------------------------------------------- | ------------------------------------ |
| `authorized_ip_ranges`                            | `authorized_ip_ranges` (now `list`)  |
| `virtual_network_integration_enabled`             | `enable_vnet_integration`            |
| (top-level) `run_command_enabled`                 | `disable_run_command` (inverted)     |
| (top-level) `private_cluster_enabled`             | `enable_private_cluster`             |
| (top-level) `private_cluster_public_fqdn_enabled` | `enable_private_cluster_public_fqdn` |
| (top-level) `private_dns_zone_id`                 | `private_dns_zone`                   |

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
  private_dns_zone                   = "/subscriptions/.../privateDnsZones/..."
  disable_run_command                = true  # Note: inverted logic
}
```

### Addon Profile Changes

All addon-related configurations have been restructured into dedicated `addon_profile_*` variables with a consistent structure:

```hcl
addon_profile_<name> = {
  enabled  = bool
  config   = { ... }  # Addon-specific configuration
  identity = { ... }  # Optional identity configuration
}
```

#### OMS Agent Migration

**Old Configuration:**

```hcl
oms_agent = {
  log_analytics_workspace_id      = "/subscriptions/.../workspaces/..."
  msi_auth_for_monitoring_enabled = true
}
```

**New Configuration:**

```hcl
addon_profile_oms_agent = {
  enabled = true
  config = {
    log_analytics_workspace_resource_id = "/subscriptions/.../workspaces/..."
    use_aad_auth                        = true
  }
}
```

#### Key Vault Secrets Provider Migration

**Old Configuration:**

```hcl
key_vault_secrets_provider = {
  secret_rotation_enabled  = true
  secret_rotation_interval = "2m"
}
```

**New Configuration:**

```hcl
addon_profile_key_vault_secrets_provider = {
  enabled = true
  config = {
    enable_secret_rotation = true
    rotation_poll_interval = "2m"
  }
}
```

#### Ingress Application Gateway Migration

**Old Configuration:**

```hcl
ingress_application_gateway = {
  gateway_id   = "/subscriptions/.../applicationGateways/..."
  gateway_name = "my-gateway"
  subnet_cidr  = "10.0.0.0/24"
  subnet_id    = "/subscriptions/.../subnets/..."
}
```

**New Configuration:**

```hcl
addon_profile_ingress_application_gateway = {
  enabled = true
  config = {
    application_gateway_id   = "/subscriptions/.../applicationGateways/..."
    application_gateway_name = "my-gateway"
    subnet_cidr              = "10.0.0.0/24"
    subnet_id                = "/subscriptions/.../subnets/..."
  }
}
```

#### Azure Policy Migration

**Old Configuration:**

```hcl
azure_policy_enabled = true
```

**New Configuration:**

```hcl
addon_profile_azure_policy = {
  enabled = true
}
```

#### Confidential Computing Migration

**Old Configuration:**

```hcl
confidential_computing = {
  sgx_quote_helper_enabled = true
}
```

**New Configuration:**

```hcl
addon_profile_confidential_computing = {
  enabled = true
  config = {
    # SGX quote helper is implicitly enabled when the addon is enabled
  }
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
  name = "Base"     # Options: Automatic, Base
  tier = "Standard" # Options: Free, Standard, Premium
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
| `eviction_policy`              | `scale_set_eviction_policy`                 |
| `priority`                     | `scale_set_priority`                        |
| `snapshot_id`                  | `creation_data.source_resource_id`          |
| `gpu_driver`                   | `gpu_profile.driver`                        |

#### Kubelet Config Changes

| Old Attribute            | New Attribute             |
| ------------------------ | ------------------------- |
| `cpu_cfs_quota_enabled`  | `cpu_cfs_quota`           |
| `container_log_max_line` | `container_log_max_files` |
| `pod_max_pid`            | `pod_max_pids`            |
| N/A                      | `fail_swap_on`            |

#### Linux OS Config Changes

The `sysctl_config` block has been renamed to `sysctls`, and the following attributes changed:

| Old Attribute                                                           | New Attribute                                               |
| ----------------------------------------------------------------------- | ----------------------------------------------------------- |
| `net_ipv4_ip_local_port_range_min` + `net_ipv4_ip_local_port_range_max` | `net_ipv4_ip_local_port_range` (string, e.g., "1024 65535") |
| `net_ipv4_tcp_keepalive_intvl`                                          | `net_ipv4_tcpkeepalive_intvl`                               |

#### Network Profile Changes (Agent Pool)

| Old Attribute                    | New Attribute                                                        |
| -------------------------------- | -------------------------------------------------------------------- |
| `application_security_group_ids` | `application_security_groups`                                        |
| `node_public_ip_tags` (map)      | `node_public_ip_tags` (list of objects with `ip_tag_type` and `tag`) |

#### Windows Profile Changes (Agent Pool)

| Old Attribute          | New Attribute                           |
| ---------------------- | --------------------------------------- |
| `outbound_nat_enabled` | `disable_outbound_nat` (inverted logic) |

#### Upgrade Settings Changes

| Old Attribute | New Attribute               |
| ------------- | --------------------------- |
| `max_surge`   | `max_surge`                 |
| N/A           | `max_unavailable`           |
| N/A           | `undrainable_node_behavior` |

#### New Agent Pool Features

The following new features are available in agent pools:

- `creation_data` - For creating from snapshots
- `gateway_profile` - Gateway agent pool configuration
- `gpu_profile` - GPU driver settings
- `local_dns_profile` - Per-node local DNS configuration
- `message_of_the_day` - Linux node MOTD
- `output_data_only` - Output body without creating resource
- `pod_ip_allocation_mode` - Pod IP allocation mode
- `scale_set_eviction_policy` - Spot VM eviction policy
- `scale_set_priority` - VM priority (Regular/Spot)
- `security_profile` - Trusted launch settings
- `virtual_machines_profile` - VirtualMachines agent pool specs

### Network Profile Changes (Cluster)

The cluster `network_profile` has been significantly restructured:

| Old Attribute                                       | New Attribute                                                        |
| --------------------------------------------------- | -------------------------------------------------------------------- |
| `network_data_plane`                                | `network_dataplane`                                                  |
| `ip_versions`                                       | `ip_families`                                                        |
| `load_balancer_profile.managed_outbound_ip_count`   | `load_balancer_profile.managed_outbound_ips.count`                   |
| `load_balancer_profile.managed_outbound_ipv6_count` | `load_balancer_profile.managed_outbound_ips.count_i_pv6`             |
| `load_balancer_profile.outbound_ip_address_ids`     | `load_balancer_profile.outbound_ips.public_ips[].id`                 |
| `load_balancer_profile.outbound_ip_prefix_ids`      | `load_balancer_profile.outbound_ip_prefixes.public_ip_prefixes[].id` |
| `load_balancer_profile.outbound_ports_allocated`    | `load_balancer_profile.allocated_outbound_ports`                     |
| `nat_gateway_profile.managed_outbound_ip_count`     | `nat_gateway_profile.managed_outbound_ip_profile.count`              |
| N/A                                                 | `advanced_networking` (new)                                          |
| N/A                                                 | `static_egress_gateway_profile` (new)                                |

**Old Configuration:**

```hcl
network_profile = {
  network_plugin      = "azure"
  network_policy      = "azure"
  network_plugin_mode = "overlay"
  load_balancer_profile = {
    managed_outbound_ip_count = 2
    outbound_ports_allocated  = 8000
  }
}
```

**New Configuration:**

```hcl
network_profile = {
  network_plugin      = "azure"
  network_policy      = "azure"
  network_plugin_mode = "overlay"
  load_balancer_profile = {
    managed_outbound_ips = {
      count = 2
    }
    allocated_outbound_ports = 8000
  }
}
```

### Auto Scaler Profile Changes

| Old Attribute                                   | New Attribute                           |
| ----------------------------------------------- | --------------------------------------- |
| `daemonset_eviction_for_empty_nodes_enabled`    | `daemonset_eviction_for_empty_nodes`    |
| `daemonset_eviction_for_occupied_nodes_enabled` | `daemonset_eviction_for_occupied_nodes` |
| `empty_bulk_delete_max`                         | `max_empty_bulk_delete`                 |
| `ignore_daemonsets_utilization_enabled`         | `ignore_daemonsets_utilization`         |
| `max_node_provisioning_time`                    | `max_node_provision_time`               |
| `max_unready_nodes`                             | `ok_total_unready_count`                |
| `max_unready_percentage`                        | `max_total_unready_percentage`          |
| `scale_down_unneeded`                           | `scale_down_unneeded_time`              |
| `scale_down_unready`                            | `scale_down_unready_time`               |

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
      ingress_gateways = [
        {
          enabled = true
          mode    = "Internal"
        }
      ]
      egress_gateways = [
        {
          enabled = false
          name    = "istio-egressgateway"
        }
      ]
    }
    certificate_authority = {
      plugin = {
        key_vault_id           = "/subscriptions/.../vaults/..."
        root_cert_object_name  = "root-cert"
        cert_chain_object_name = "cert-chain"
        cert_object_name       = "cert"
        key_object_name        = "key"
      }
    }
  }
}
```

### Storage Profile Changes

The storage profile structure has been updated:

**Old Configuration:**

```hcl
storage_profile = {
  blob_driver_enabled         = true
  disk_driver_enabled         = true
  file_driver_enabled         = true
  snapshot_controller_enabled = true
}
```

**New Configuration:**

```hcl
storage_profile = {
  blob_csi_driver = {
    enabled = true
  }
  disk_csi_driver = {
    enabled = true
  }
  file_csi_driver = {
    enabled = true
  }
  snapshot_controller = {
    enabled = true
  }
}
```

### Linux Profile Changes

The structure has been updated:

**Old Configuration:**

```hcl
linux_profile = {
  admin_username = "azureuser"
  ssh_key        = "ssh-rsa AAAA..."
}
```

**New Configuration:**

```hcl
linux_profile = {
  admin_username = "azureuser"
  ssh = {
    public_keys = [
      {
        key_data = "ssh-rsa AAAA..."
      }
    ]
  }
}
```

### Windows Profile Changes

The structure has been updated:

**Old Configuration:**

```hcl
windows_profile = {
  admin_username = "azureuser"
  license        = "Windows_Server"
  gmsa = {
    root_domain = "example.com"
    dns_server  = "10.0.0.4"
  }
}

windows_profile_password = "SecurePassword123!"
```

**New Configuration:**

```hcl
windows_profile = {
  admin_username   = "azureuser"
  admin_password   = "SecurePassword123!"  # Can also use windows_profile_password variable
  license_type     = "Windows_Server"
  enable_csi_proxy = false
  gmsa_profile = {
    enabled          = true
    root_domain_name = "example.com"
    dns_server       = "10.0.0.4"
  }
}

# Or use the separate variable:
windows_profile_password         = "SecurePassword123!"
windows_profile_password_version = "v1"  # Required when using windows_profile_password
```

| Old Attribute      | New Attribute                   |
| ------------------ | ------------------------------- |
| `license`          | `license_type`                  |
| `gmsa.root_domain` | `gmsa_profile.root_domain_name` |
| `gmsa.dns_server`  | `gmsa_profile.dns_server`       |
| N/A                | `enable_csi_proxy`              |
| N/A                | `gmsa_profile.enabled`          |

### Web App Routing Changes

**Old Configuration:**

```hcl
web_app_routing_dns_zone_ids = {
  "zone1" = ["/subscriptions/.../dnsZones/..."]
  "zone2" = ["/subscriptions/.../dnsZones/..."]
}

default_nginx_controller = "AnnotationControlled"
```

**New Configuration:**

```hcl
ingress_profile = {
  web_app_routing = {
    enabled = true
    dns_zone_resource_ids = [
      "/subscriptions/.../dnsZones/...",
      "/subscriptions/.../dnsZones/..."
    ]
    nginx = {
      default_ingress_controller_type = "AnnotationControlled"
    }
  }
}
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

### Workload Autoscaler Profile Changes

**Old Configuration:**

```hcl
workload_autoscaler_profile = {
  keda_enabled = true
  vpa_enabled  = true
}
```

**New Configuration:**

```hcl
workload_auto_scaler_profile = {
  keda = {
    enabled = true
  }
  vertical_pod_autoscaler = {
    enabled = true
  }
}
```

### Maintenance Window Changes

The separate maintenance window variables have been consolidated into a single `maintenanceconfiguration` map variable that supports multiple maintenance configurations.

**Old Configuration:**

```hcl
maintenance_window = {
  allowed = [
    {
      day   = "Sunday"
      hours = [1, 2]
    }
  ]
  not_allowed = [
    {
      start = "2023-12-25T00:00:00Z"
      end   = "2023-12-26T00:00:00Z"
    }
  ]
}

maintenance_window_auto_upgrade = {
  frequency   = "Weekly"
  interval    = 1
  duration    = 4
  day_of_week = "Sunday"
  start_time  = "02:00"
  utc_offset  = "+00:00"
}

maintenance_window_node_os = {
  frequency   = "Weekly"
  interval    = 1
  duration    = 4
  day_of_week = "Sunday"
  start_time  = "02:00"
  utc_offset  = "+00:00"
}
```

**New Configuration:**

```hcl
maintenanceconfiguration = {
  # Default maintenance configuration (for general cluster maintenance)
  default = {
    name = "default"
    time_in_week = [
      {
        day        = "Sunday"
        hour_slots = [1, 2]
      }
    ]
    not_allowed_time = [
      {
        start = "2023-12-25T00:00:00Z"
        end   = "2023-12-26T00:00:00Z"
      }
    ]
  }

  # Auto-upgrade maintenance configuration
  aksManagedAutoUpgradeSchedule = {
    name = "aksManagedAutoUpgradeSchedule"
    maintenance_window = {
      duration_hours = 4
      start_time     = "02:00"
      utc_offset     = "+00:00"
      schedule = {
        weekly = {
          day_of_week    = "Sunday"
          interval_weeks = 1
        }
      }
      not_allowed_dates = [
        {
          start = "2023-12-25"
          end   = "2023-12-26"
        }
      ]
    }
  }

  # Node OS upgrade maintenance configuration
  aksManagedNodeOSUpgradeSchedule = {
    name = "aksManagedNodeOSUpgradeSchedule"
    maintenance_window = {
      duration_hours = 4
      start_time     = "02:00"
      utc_offset     = "+00:00"
      schedule = {
        weekly = {
          day_of_week    = "Sunday"
          interval_weeks = 1
        }
      }
    }
  }
}
```

| Old Variable                      | New Configuration Key                                      |
| --------------------------------- | ---------------------------------------------------------- |
| `maintenance_window`              | `maintenanceconfiguration.default`                         |
| `maintenance_window_auto_upgrade` | `maintenanceconfiguration.aksManagedAutoUpgradeSchedule`   |
| `maintenance_window_node_os`      | `maintenanceconfiguration.aksManagedNodeOSUpgradeSchedule` |

#### Maintenance Window Schedule Options

The `maintenance_window.schedule` block supports four mutually exclusive schedule types:

- **daily**: For schedules like "recur every day" or "recur every 3 days"
  - `interval_days`: Number of days between occurrences
- **weekly**: For schedules like "recur every Monday" or "recur every 3 weeks on Wednesday"
  - `day_of_week`: The day of the week (Monday, Tuesday, etc.)
  - `interval_weeks`: Number of weeks between occurrences
- **absolute_monthly**: For schedules like "recur every month on the 15th"
  - `day_of_month`: The date of the month (1-31)
  - `interval_months`: Number of months between occurrences
- **relative_monthly**: For schedules like "recur every month on the first Monday"
  - `day_of_week`: The day of the week
  - `interval_months`: Number of months between occurrences
  - `week_index`: Which week (First, Second, Third, Fourth, Last)

## New Variables

The following new variables have been added:

| Variable                                    | Type     | Description                                                              |
| ------------------------------------------- | -------- | ------------------------------------------------------------------------ |
| `parent_id`                                 | `string` | Resource group resource ID (replaces `resource_group_name`)              |
| `aad_profile`                               | `object` | Azure Active Directory integration settings                              |
| `addon_profile_azure_policy`                | `object` | Azure Policy addon configuration                                         |
| `addon_profile_confidential_computing`      | `object` | Confidential computing addon configuration                               |
| `addon_profile_ingress_application_gateway` | `object` | Ingress Application Gateway addon configuration                          |
| `addon_profile_key_vault_secrets_provider`  | `object` | Key Vault Secrets Provider addon configuration                           |
| `addon_profile_oms_agent`                   | `object` | OMS Agent addon configuration                                            |
| `addon_profiles_extra`                      | `map`    | Additional addon profiles                                                |
| `ai_toolchain_operator_profile`             | `object` | AI toolchain operator configuration                                      |
| `auto_upgrade_profile`                      | `object` | Auto upgrade profile with upgrade and node OS channels                   |
| `azure_monitor_profile`                     | `object` | Azure Monitor profile for Prometheus metrics                             |
| `bootstrap_profile`                         | `object` | Bootstrap profile for artifact sources                                   |
| `extended_location`                         | `object` | Extended location (Edge Zone) configuration                              |
| `fqdn_subdomain`                            | `string` | FQDN subdomain for private clusters                                      |
| `identity_profile`                          | `map`    | Identity profile including kubelet identity                              |
| `ingress_profile`                           | `object` | Ingress profile including web app routing                                |
| `maintenanceconfiguration`                  | `map`    | Unified maintenance configuration for cluster, auto-upgrade, and node OS |
| `metrics_profile`                           | `object` | Metrics profile for cost analysis                                        |
| `node_provisioning_profile`                 | `object` | Node provisioning profile (Karpenter)                                    |
| `node_resource_group_profile`               | `object` | Node resource group lockdown settings                                    |
| `oidc_issuer_profile`                       | `object` | OIDC issuer profile                                                      |
| `pod_identity_profile`                      | `object` | Pod identity profile                                                     |
| `private_link_resources`                    | `list`   | Private link resources configuration                                     |
| `public_network_access`                     | `string` | Public network access setting                                            |
| `security_profile`                          | `object` | Security profile (Defender, Image Cleaner, Workload Identity, KMS)       |
| `service_principal_profile`                 | `object` | Service principal configuration                                          |
| `sku`                                       | `object` | SKU configuration with name and tier                                     |
| `upgrade_settings`                          | `object` | Upgrade settings with override options                                   |
| `workload_auto_scaler_profile`              | `object` | Workload autoscaler profile (KEDA, VPA)                                  |
| `windows_profile_password_version`          | `string` | Version of Windows admin password                                        |

### Security Profile Example

```hcl
security_profile = {
  azure_key_vault_kms = {
    enabled                  = true
    key_id                   = "https://myvault.vault.azure.net/keys/mykey/version"
    key_vault_network_access = "Private"
    key_vault_resource_id    = "/subscriptions/.../vaults/myvault"
  }
  defender = {
    log_analytics_workspace_resource_id = "/subscriptions/.../workspaces/..."
    security_monitoring = {
      enabled = true
    }
  }
  image_cleaner = {
    enabled        = true
    interval_hours = 48
  }
  workload_identity = {
    enabled = true
  }
}
```

### Identity Profile Example (Kubelet Identity)

```hcl
identity_profile = {
  kubeletidentity = {
    resource_id = "/subscriptions/.../userAssignedIdentities/my-kubelet-identity"
    client_id   = "00000000-0000-0000-0000-000000000000"
    object_id   = "00000000-0000-0000-0000-000000000000"
  }
}
```

### Azure Monitor Profile Example

```hcl
azure_monitor_profile = {
  metrics = {
    enabled = true
    kube_state_metrics = {
      metric_annotations_allow_list = "namespaces=[kubernetes.io/team]"
      metric_labels_allowlist       = "namespaces=[app]"
    }
  }
}
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
8. [ ] Migrate `azure_active_directory_role_based_access_control` to `aad_profile`
9. [ ] Replace `role_based_access_control_enabled` with `enable_rbac`
10. [ ] Replace `local_account_disabled` with `disable_local_accounts`
11. [ ] Migrate addon configurations to `addon_profile_*` variables
12. [ ] Migrate `oms_agent` to `addon_profile_oms_agent`
13. [ ] Migrate `key_vault_secrets_provider` to `addon_profile_key_vault_secrets_provider`
14. [ ] Migrate `ingress_application_gateway` to `addon_profile_ingress_application_gateway`
15. [ ] Replace `azure_policy_enabled` with `addon_profile_azure_policy`
16. [ ] Update `linux_profile` structure (ssh key format)
17. [ ] Update `windows_profile` structure
18. [ ] Update `network_profile` structure (load balancer, NAT gateway)
19. [ ] Update `storage_profile` structure
20. [ ] Migrate `web_app_routing_dns_zone_ids` to `ingress_profile`
21. [ ] Migrate `service_mesh_profile` structure
22. [ ] Migrate `auto_scaler_profile` attribute names
23. [ ] Migrate `workload_autoscaler_profile` to `workload_auto_scaler_profile`
24. [ ] Migrate maintenance windows to `maintenanceconfiguration` map variable
25. [ ] Migrate security-related settings to `security_profile`
26. [ ] Migrate `automatic_upgrade_channel` to `auto_upgrade_profile`
27. [ ] Migrate `kubelet_identity` to `identity_profile`
28. [ ] Remove deprecated variables (`service_principal`, `kubelet_identity`, etc.)
29. [ ] Update any references to renamed outputs
30. [ ] Run `terraform plan` to verify migration
31. [ ] Apply changes

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

  azure_active_directory_role_based_access_control = {
    tenant_id              = "00000000-0000-0000-0000-000000000000"
    admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]
    azure_rbac_enabled     = true
  }

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

  azure_policy_enabled = true

  oms_agent = {
    log_analytics_workspace_id      = "/subscriptions/.../workspaces/..."
    msi_auth_for_monitoring_enabled = true
  }

  linux_profile = {
    admin_username = "azureuser"
    ssh_key        = "ssh-rsa AAAA..."
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
    private_dns_zone                   = "/subscriptions/.../privateDnsZones/..."
    disable_run_command                = true
  }

  enable_rbac            = true
  disable_local_accounts = true

  aad_profile = {
    tenant_id              = "00000000-0000-0000-0000-000000000000"
    admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]
    enable_azure_rbac      = true
    managed                = true
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

  addon_profile_azure_policy = {
    enabled = true
  }

  addon_profile_oms_agent = {
    enabled = true
    config = {
      log_analytics_workspace_resource_id = "/subscriptions/.../workspaces/..."
      use_aad_auth                        = true
    }
  }

  linux_profile = {
    admin_username = "azureuser"
    ssh = {
      public_keys = [
        {
          key_data = "ssh-rsa AAAA..."
        }
      ]
    }
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
