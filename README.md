<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-template

This is a template repo for Terraform Azure Verified Modules.

Things to do:

1. Set up a GitHub repo environment called `test`.
1. Configure environment protection rule to ensure that approval is required before deploying to this environment.
1. Create a user-assigned managed identity in your test subscription.
1. Create a role assignment for the managed identity on your test subscription, use the minimum required role.
1. Configure federated identity credentials on the user assigned managed identity. Use the GitHub environment.
1. Search and update TODOs within the code and remove the TODO comments once complete.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
>
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9.2)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (>= 1.12, < 3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (< 4.0.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_null"></a> [null](#requirement\_null) (>= 3.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azapi_update_resource.aks_cluster_http_proxy_config_no_proxy](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) (resource)
- [azapi_update_resource.aks_cluster_post_create](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/update_resource) (resource)
- [azurerm_kubernetes_cluster.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_private_endpoint.this_managed_dns_zone_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_private_endpoint.this_unmanaged_dns_zone_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_private_endpoint_application_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint_application_security_group_association) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [null_resource.http_proxy_config_no_proxy_keeper](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) (resource)
- [null_resource.kubernetes_version_keeper](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) (resource)
- [random_string.dns_prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_default_node_pool"></a> [default\_node\_pool](#input\_default\_node\_pool)

Description: Required. The default node pool for the Kubernetes cluster.

Type:

```hcl
object({
    name                          = string
    vm_size                       = string
    capacity_reservation_group_id = optional(string)
    auto_scaling_enabled          = optional(bool, false)
    host_encryption_enabled       = optional(bool)
    node_public_ip_enabled        = optional(bool)
    gpu_instance                  = optional(string)
    host_group_id                 = optional(string)
    fips_enabled                  = optional(bool)
    kubelet_disk_type             = optional(string)
    max_pods                      = optional(number)
    node_public_ip_prefix_id      = optional(string)
    node_labels                   = optional(map(string))
    only_critical_addons_enabled  = optional(string)
    orchestrator_version          = optional(string)
    os_disk_size_gb               = optional(string)
    os_disk_type                  = optional(string)
    os_sku                        = optional(string)
    pod_subnet_id                 = optional(string)
    proximity_placement_group_id  = optional(string)
    scale_down_mode               = optional(string)
    snapshot_id                   = optional(string)
    temporary_name_for_rotation   = optional(string)
    type                          = optional(string, "VirtualMachineScaleSets")
    tags                          = optional(map(string))
    ultra_ssd_enabled             = optional(bool)
    vnet_subnet_id                = optional(string)
    workload_runtime              = optional(string)
    zones                         = optional(list(string))
    max_count                     = optional(number)
    min_count                     = optional(number)
    node_count                    = optional(number)
    kubelet_config = optional(object({
      cpu_manager_policy        = optional(string)
      cpu_cfs_quota_enabled     = optional(bool, true)
      cpu_cfs_quota_period      = optional(string)
      image_gc_high_threshold   = optional(number)
      image_gc_low_threshold    = optional(number)
      topology_manager_policy   = optional(string)
      allowed_unsafe_sysctls    = optional(set(string))
      container_log_max_size_mb = optional(number)
      container_log_max_line    = optional(number)
      pod_max_pid               = optional(number)
    }))
    linux_os_config = optional(object({
      sysctl_config = optional(object({
        fs_aio_max_nr                      = optional(number)
        fs_file_max                        = optional(number)
        fs_inotify_max_user_watches        = optional(number)
        fs_nr_open                         = optional(number)
        kernel_threads_max                 = optional(number)
        net_core_netdev_max_backlog        = optional(number)
        net_core_optmem_max                = optional(number)
        net_core_rmem_default              = optional(number)
        net_core_rmem_max                  = optional(number)
        net_core_somaxconn                 = optional(number)
        net_core_wmem_default              = optional(number)
        net_core_wmem_max                  = optional(number)
        net_ipv4_ip_local_port_range_min   = optional(number)
        net_ipv4_ip_local_port_range_max   = optional(number)
        net_ipv4_neigh_default_gc_thresh1  = optional(number)
        net_ipv4_neigh_default_gc_thresh2  = optional(number)
        net_ipv4_neigh_default_gc_thresh3  = optional(number)
        net_ipv4_tcp_fin_timeout           = optional(number)
        net_ipv4_tcp_keepalive_intvl       = optional(number)
        net_ipv4_tcp_keepalive_probes      = optional(number)
        net_ipv4_tcp_keepalive_time        = optional(number)
        net_ipv4_tcp_max_syn_backlog       = optional(number)
        net_ipv4_tcp_max_tw_buckets        = optional(number)
        net_ipv4_tcp_tw_reuse              = optional(bool)
        net_netfilter_nf_conntrack_buckets = optional(number)
        net_netfilter_nf_conntrack_max     = optional(number)
        vm_max_map_count                   = optional(number)
        vm_swappiness                      = optional(number)
        vm_vfs_cache_pressure              = optional(number)
      }))

      transparent_huge_page_enabled = optional(string)
      transparent_huge_page_defrag  = optional(string)
      swap_file_size_mb             = optional(number)
    }))
    upgrade_settings = optional(object({
      drain_timeout_in_minutes      = optional(number)
      node_soak_duration_in_minutes = optional(number)
      max_surge                     = string
    }))

  })
```

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of this resource.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_aci_connector_linux_subnet_name"></a> [aci\_connector\_linux\_subnet\_name](#input\_aci\_connector\_linux\_subnet\_name)

Description: The subnet name for the ACI connector Linux.

Type: `string`

Default: `null`

### <a name="input_api_server_access_profile"></a> [api\_server\_access\_profile](#input\_api\_server\_access\_profile)

Description: The API server access profile for the Kubernetes cluster.

Type: `list(string)`

Default: `null`

### <a name="input_auto_scaler_profile"></a> [auto\_scaler\_profile](#input\_auto\_scaler\_profile)

Description: The auto scaler profile for the Kubernetes cluster.

Type:

```hcl
object({
    balance_similar_node_groups      = optional(string)
    expander                         = optional(string)
    max_graceful_termination_sec     = optional(string)
    max_node_provisioning_time       = optional(string)
    max_unready_nodes                = optional(string)
    max_unready_percentage           = optional(string)
    new_pod_scale_up_delay           = optional(string)
    scale_down_delay_after_add       = optional(string)
    scale_down_delay_after_delete    = optional(string)
    scale_down_delay_after_failure   = optional(string)
    scale_down_unneeded              = optional(string)
    scale_down_unready               = optional(string)
    scale_down_utilization_threshold = optional(string)
    empty_bulk_delete_max            = optional(string)
    skip_nodes_with_local_storage    = optional(string)
    skip_nodes_with_system_pods      = optional(string)
  })
```

Default: `null`

### <a name="input_automatic_upgrade_channel"></a> [automatic\_upgrade\_channel](#input\_automatic\_upgrade\_channel)

Description: (Optional) The upgrade channel for this Kubernetes Cluster. Possible values are `patch`, `rapid`, `node-image` and `stable`. By default automatic-upgrades are turned off. Note that you cannot specify the patch version using `kubernetes_version` or `orchestrator_version` when using the `patch` upgrade channel. See [the documentation](https://learn.microsoft.com/en-us/azure/aks/auto-upgrade-cluster) for more information

Type: `string`

Default: `null`

### <a name="input_azure_active_directory_role_based_access_control"></a> [azure\_active\_directory\_role\_based\_access\_control](#input\_azure\_active\_directory\_role\_based\_access\_control)

Description: The Azure Active Directory role-based access control for the Kubernetes cluster.

Type:

```hcl
object({
    tenant_id              = optional(string)
    admin_group_object_ids = optional(list(string))
    azure_rbac_enabled     = optional(bool)
  })
```

Default: `null`

### <a name="input_azure_policy_enabled"></a> [azure\_policy\_enabled](#input\_azure\_policy\_enabled)

Description: Whether or not Azure Policy is enabled for the Kubernetes cluster.

Type: `bool`

Default: `true`

### <a name="input_cluster_suffix"></a> [cluster\_suffix](#input\_cluster\_suffix)

Description: Optional. The suffix to append to the Kubernetes cluster name if create\_before\_destroy is set to true on the nodepools.

Type: `string`

Default: `""`

### <a name="input_cost_analysis_enabled"></a> [cost\_analysis\_enabled](#input\_cost\_analysis\_enabled)

Description: Whether or not cost analysis is enabled for the Kubernetes cluster. SKU must be Standard or Premium.

Type: `bool`

Default: `false`

### <a name="input_create_nodepools_before_destroy"></a> [create\_nodepools\_before\_destroy](#input\_create\_nodepools\_before\_destroy)

Description: Whether or not to create node pools before destroying the old ones. This is the opposite of the default behavior. Set this to true if zero downtime is required during nodepool redeployments such as changes to snapshot\_id.

Type: `bool`

Default: `false`

### <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key)

Description: A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.

Type:

```hcl
object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
```

Default: `null`

### <a name="input_defender_log_analytics_workspace_id"></a> [defender\_log\_analytics\_workspace\_id](#input\_defender\_log\_analytics\_workspace\_id)

Description: The log analytics workspace ID for the Microsoft Defender.

Type: `string`

Default: `null`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.

Type:

```hcl
map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_disk_encryption_set_id"></a> [disk\_encryption\_set\_id](#input\_disk\_encryption\_set\_id)

Description: The disk encryption set ID for the Kubernetes cluster.

Type: `string`

Default: `null`

### <a name="input_dns_prefix"></a> [dns\_prefix](#input\_dns\_prefix)

Description: The DNS prefix specified when creating the managed cluster. If you do not specify one, a random prefix will be generated.

Type: `string`

Default: `""`

### <a name="input_dns_prefix_private_cluster"></a> [dns\_prefix\_private\_cluster](#input\_dns\_prefix\_private\_cluster)

Description: The Private Cluster DNS prefix specified when creating a private cluster. Required if deploying private cluster.

Type: `string`

Default: `""`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_http_application_routing_enabled"></a> [http\_application\_routing\_enabled](#input\_http\_application\_routing\_enabled)

Description: Whether or not HTTP application routing is enabled for the Kubernetes cluster.

Type: `bool`

Default: `false`

### <a name="input_http_proxy_config"></a> [http\_proxy\_config](#input\_http\_proxy\_config)

Description: The HTTP proxy configuration for the Kubernetes cluster.

Type:

```hcl
object({
    http_proxy  = optional(string)
    https_proxy = optional(string)
    no_proxy    = optional(string)
    trusted_ca  = optional(string)
  })
```

Default: `null`

### <a name="input_identity"></a> [identity](#input\_identity)

Description: The type and id of identities to use for the Kubernetes cluster.

Type:

```hcl
object({
    type         = string
    identity_ids = optional(list(string))
  })
```

Default:

```json
{
  "type": "SystemAssigned"
}
```

### <a name="input_image_cleaner_enabled"></a> [image\_cleaner\_enabled](#input\_image\_cleaner\_enabled)

Description: Whether or not the image cleaner is enabled for the Kubernetes cluster.

Type: `bool`

Default: `false`

### <a name="input_ingress_application_gateway"></a> [ingress\_application\_gateway](#input\_ingress\_application\_gateway)

Description: The ingress application gateway for the Kubernetes cluster.

Type:

```hcl
object({
    gateway_id   = optional(string)
    gateway_name = optional(string)
    subnet_cidr  = optional(string)
    subnet_id    = optional(string)
  })
```

Default: `null`

### <a name="input_key_management_service"></a> [key\_management\_service](#input\_key\_management\_service)

Description: The key management service for the Kubernetes cluster.

Type:

```hcl
object({
    key_vault_key_id         = string
    key_vault_network_access = string
  })
```

Default: `null`

### <a name="input_key_vault_secrets_provider"></a> [key\_vault\_secrets\_provider](#input\_key\_vault\_secrets\_provider)

Description: The key vault secrets provider for the Kubernetes cluster. Either rotation enabled or rotation interval must be specified.

Type:

```hcl
object({
    secret_rotation_enabled  = optional(bool)
    secret_rotation_interval = optional(string)
  })
```

Default: `null`

### <a name="input_kubelet_identity"></a> [kubelet\_identity](#input\_kubelet\_identity)

Description: The kubelet identity for the Kubernetes cluster.

Type:

```hcl
object({
    client_id                 = optional(string)
    object_id                 = optional(string)
    user_assigned_identity_id = optional(string)
  })
```

Default: `null`

### <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version)

Description: The version of Kubernetes to use for the managed cluster.

Type: `string`

Default: `null`

### <a name="input_linux_profile"></a> [linux\_profile](#input\_linux\_profile)

Description: The Linux profile for the Kubernetes cluster.

Type:

```hcl
object({
    admin_username = string
    ssh_key        = string
  })
```

Default: `null`

### <a name="input_local_account_disabled"></a> [local\_account\_disabled](#input\_local\_account\_disabled)

Description: Defaults to true. Whether or not the local account should be disabled on the Kubernetes cluster. Azure RBAC must be enabled.

Type: `bool`

Default: `true`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window)

Description: The maintenance window for the Kubernetes cluster.

Type:

```hcl
object({
    allowed = object({
      day   = string
      hours = number
    })
    not_allowed = object({
      start = string
      end   = string
    })
  })
```

Default: `null`

### <a name="input_maintenance_window_auto_upgrade"></a> [maintenance\_window\_auto\_upgrade](#input\_maintenance\_window\_auto\_upgrade)

Description: values for maintenance window auto upgrade

Type:

```hcl
object({
    frequency    = string
    interval     = string
    duration     = number
    day_of_week  = optional(string)
    day_of_month = optional(number)
    week_index   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    start_date   = optional(string)
    not_allowed = optional(object({
      start = string
      end   = string
    }))
  })
```

Default: `null`

### <a name="input_maintenance_window_node_os"></a> [maintenance\_window\_node\_os](#input\_maintenance\_window\_node\_os)

Description: values for maintenance window node os

Type:

```hcl
object({
    frequency    = string
    interval     = string
    duration     = number
    day_of_week  = optional(string)
    day_of_month = optional(number)
    week_index   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    start_date   = optional(string)
    not_allowed = optional(object({
      start = string
      end   = string
    }))
  })
```

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description: Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_monitor_metrics"></a> [monitor\_metrics](#input\_monitor\_metrics)

Description: The monitor metrics for the Kubernetes cluster. Both required if enabling Prometheus

Type:

```hcl
object({
    annotations_allowed = optional(bool)
    labels_allowed      = optional(bool)
  })
```

Default: `null`

### <a name="input_network_profile"></a> [network\_profile](#input\_network\_profile)

Description: The network profile for the Kubernetes cluster.

Type:

```hcl
object({
    network_plugin      = string
    network_mode        = optional(string)
    network_policy      = optional(string)
    dns_service_ip      = optional(string)
    network_data_plane  = optional(string)
    network_plugin_mode = optional(string)
    outbound_type       = optional(string, "loadBalancer")
    pod_cidr            = optional(string)
    pod_cidrs           = optional(list(string))
    service_cidr        = optional(string)
    service_cidrs       = optional(list(string))
    ip_versions         = optional(list(string))
    load_balancer_sku   = optional(string)
    load_balancer_profile = optional(object({
      managed_outbound_ip_count   = optional(number)
      managed_outbound_ipv6_count = optional(number)
      outbound_ip_address_ids     = optional(list(string))
      outbound_ip_prefix_ids      = optional(list(string))
      outbound_ports_allocated    = optional(number)
      idle_timeout_in_minutes     = optional(number)
    }))
    nat_gateway_profile = optional(object({
      managed_outbound_ip_count = optional(number)
      idle_timeout_in_minutes   = optional(number)
    }))
  })
```

Default:

```json
{
  "network_plugin": "azure",
  "network_plugin_mode": "overlay",
  "network_policy": "azure"
}
```

### <a name="input_node_os_channel_upgrade"></a> [node\_os\_channel\_upgrade](#input\_node\_os\_channel\_upgrade)

Description: The node OS channel upgrade for the Kubernetes cluster.

Type: `string`

Default: `"NodeImage"`

### <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools)

Description: Optional. The additional node pools for the Kubernetes cluster.

Type:

```hcl
map(object({
    name                          = string
    vm_size                       = string
    capacity_reservation_group_id = optional(string)
    auto_scaling_enabled          = optional(bool, false)
    max_count                     = optional(number)
    min_count                     = optional(number)
    node_count                    = optional(number)
    host_encryption_enabled       = optional(bool)
    node_public_ip_enabled        = optional(bool)
    eviction_policy               = optional(string)
    host_group_id                 = optional(string)
    fips_enabled                  = optional(bool)
    gpu_instance                  = optional(string)
    kubelet_disk_type             = optional(string)
    max_pods                      = optional(number)
    mode                          = optional(string)
    node_network_profile = optional(object({
      allowed_host_ports = optional(list(object({
        port_start = optional(number)
        port_end   = optional(number)
        protocol   = optional(string)
      })))
      application_security_group_ids = optional(list(string))
      node_public_ip_tags            = optional(map(string))
    }))
    node_labels                  = optional(map(string))
    node_public_ip_prefix_id     = optional(string)
    node_taints                  = optional(list(string))
    orchestrator_version         = optional(string)
    os_disk_size_gb              = optional(number)
    os_disk_type                 = optional(string)
    os_sku                       = optional(string)
    os_type                      = optional(string)
    pod_subnet_id                = optional(string)
    priority                     = optional(string)
    proximity_placement_group_id = optional(string)
    spot_max_price               = optional(string)
    snapshot_id                  = optional(string)
    tags                         = optional(map(string))
    scale_down_mode              = optional(string)
    ultra_ssd_enabled            = optional(bool)
    vnet_subnet_id               = optional(string)
    zones                        = optional(list(string))
    workload_runtime             = optional(string)
    windows_profile = optional(object({
      outbound_nat_enabled = optional(bool)
    }))
    upgrade_settings = optional(object({
      drain_timeout_in_minutes      = optional(number)
      node_soak_duration_in_minutes = optional(number)
      max_surge                     = string
    }))

    kubelet_config = optional(object({
      cpu_manager_policy        = optional(string)
      cpu_cfs_quota_enabled     = optional(bool, true)
      cpu_cfs_quota_period      = optional(string)
      image_gc_high_threshold   = optional(number)
      image_gc_low_threshold    = optional(number)
      topology_manager_policy   = optional(string)
      allowed_unsafe_sysctls    = optional(set(string))
      container_log_max_size_mb = optional(number)
      container_log_max_line    = optional(number)
      pod_max_pid               = optional(number)
    }))
    linux_os_config = optional(object({
      sysctl_config = optional(object({
        fs_aio_max_nr                      = optional(number)
        fs_file_max                        = optional(number)
        fs_inotify_max_user_watches        = optional(number)
        fs_nr_open                         = optional(number)
        kernel_threads_max                 = optional(number)
        net_core_netdev_max_backlog        = optional(number)
        net_core_optmem_max                = optional(number)
        net_core_rmem_default              = optional(number)
        net_core_rmem_max                  = optional(number)
        net_core_somaxconn                 = optional(number)
        net_core_wmem_default              = optional(number)
        net_core_wmem_max                  = optional(number)
        net_ipv4_ip_local_port_range_min   = optional(number)
        net_ipv4_ip_local_port_range_max   = optional(number)
        net_ipv4_neigh_default_gc_thresh1  = optional(number)
        net_ipv4_neigh_default_gc_thresh2  = optional(number)
        net_ipv4_neigh_default_gc_thresh3  = optional(number)
        net_ipv4_tcp_fin_timeout           = optional(number)
        net_ipv4_tcp_keepalive_intvl       = optional(number)
        net_ipv4_tcp_keepalive_probes      = optional(number)
        net_ipv4_tcp_keepalive_time        = optional(number)
        net_ipv4_tcp_max_syn_backlog       = optional(number)
        net_ipv4_tcp_max_tw_buckets        = optional(number)
        net_ipv4_tcp_tw_reuse              = optional(bool)
        net_netfilter_nf_conntrack_buckets = optional(number)
        net_netfilter_nf_conntrack_max     = optional(number)
        vm_max_map_count                   = optional(number)
        vm_swappiness                      = optional(number)
        vm_vfs_cache_pressure              = optional(number)
      }))
    }))
  }))
```

Default: `{}`

### <a name="input_node_resource_group_name"></a> [node\_resource\_group\_name](#input\_node\_resource\_group\_name)

Description: The resource group name for the node pool.

Type: `string`

Default: `null`

### <a name="input_oidc_issuer_enabled"></a> [oidc\_issuer\_enabled](#input\_oidc\_issuer\_enabled)

Description: Whether or not the OIDC issuer is enabled for the Kubernetes cluster.

Type: `bool`

Default: `false`

### <a name="input_oms_agent"></a> [oms\_agent](#input\_oms\_agent)

Description: Optional. The OMS agent for the Kubernetes cluster.

Type:

```hcl
object({
    log_analytics_workspace_id      = string
    msi_auth_for_monitoring_enabled = optional(bool)
  })
```

Default: `null`

### <a name="input_open_service_mesh_enabled"></a> [open\_service\_mesh\_enabled](#input\_open\_service\_mesh\_enabled)

Description: Whether or not open service mesh is enabled for the Kubernetes cluster.

Type: `bool`

Default: `false`

### <a name="input_private_cluster_enabled"></a> [private\_cluster\_enabled](#input\_private\_cluster\_enabled)

Description: Whether or not the Kubernetes cluster is private.

Type: `bool`

Default: `false`

### <a name="input_private_cluster_public_fqdn_enabled"></a> [private\_cluster\_public\_fqdn\_enabled](#input\_private\_cluster\_public\_fqdn\_enabled)

Description: Whether or not the private cluster public FQDN is enabled for the Kubernetes cluster.

Type: `bool`

Default: `false`

### <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id)

Description: The private DNS zone ID for the Kubernetes cluster.

Type: `string`

Default: `null`

### <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints)

Description:   A map of private endpoints to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
  - `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
    - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
    - `principal_id` - The ID of the principal to assign the role to.
    - `description` - (Optional) The description of the role assignment.
    - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
    - `condition` - (Optional) The condition which will be used to scope the role assignment.
    - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
    - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
    - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.
  - `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
    - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
    - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  - `tags` - (Optional) A mapping of tags to assign to the private endpoint.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `subresource_name` - The name of the sub resource for the private endpoint.
  - `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
  - `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
  - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
  - `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
  - `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the Key Vault.
  - `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
    - `name` - The name of the IP configuration.
    - `private_ip_address` - The private IP address of the IP configuration.

Type:

```hcl
map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string # NOTE: `subresource_name` can be excluded if the resource does not support multiple sub resource types (e.g. storage account supports blob, queue, etc)
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

### <a name="input_private_endpoints_manage_dns_zone_group"></a> [private\_endpoints\_manage\_dns\_zone\_group](#input\_private\_endpoints\_manage\_dns\_zone\_group)

Description: Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy.

Type: `bool`

Default: `true`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:   A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_role_based_access_control_enabled"></a> [role\_based\_access\_control\_enabled](#input\_role\_based\_access\_control\_enabled)

Description: Whether or not role-based access control is enabled for the Kubernetes cluster.

Type: `bool`

Default: `true`

### <a name="input_run_command_enabled"></a> [run\_command\_enabled](#input\_run\_command\_enabled)

Description: Whether or not the run command is enabled for the Kubernetes cluster.

Type: `bool`

Default: `false`

### <a name="input_service_mesh_profile"></a> [service\_mesh\_profile](#input\_service\_mesh\_profile)

Description: The service mesh profile for the Kubernetes cluster.

Type:

```hcl
object({
    mode                             = string
    internal_ingress_gateway_enabled = optional(bool)
    external_ingress_gateway_enabled = optional(bool)
    certificate_authority = optional(object({
      key_vault_id           = string
      root_cert_object_name  = string
      cert_chain_object_name = string
      cert_object_name       = string
      key_object_name        = string
    }))
  })
```

Default: `null`

### <a name="input_service_principal"></a> [service\_principal](#input\_service\_principal)

Description: The service principal for the Kubernetes cluster. Only specify this or identity, not both.

Type:

```hcl
object({
    client_id     = string
    client_secret = string
  })
```

Default: `null`

### <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier)

Description: The SKU tier of the Kubernetes Cluster. Possible values are Free, Standard, and Premium.

Type: `string`

Default: `"Standard"`

### <a name="input_storage_profile"></a> [storage\_profile](#input\_storage\_profile)

Description: Optional. The storage profile for the Kubernetes cluster.

Type:

```hcl
object({
    blob_driver_enabled         = optional(bool),
    disk_driver_enabled         = optional(bool),
    file_driver_enabled         = optional(bool),
    snapshot_controller_enabled = optional(bool)
  })
```

Default: `null`

### <a name="input_support_plan"></a> [support\_plan](#input\_support\_plan)

Description: The support plan for the Kubernetes cluster. Defaults to KubernetesOfficial.

Type: `string`

Default: `"KubernetesOfficial"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

### <a name="input_web_app_routing_dns_zone_ids"></a> [web\_app\_routing\_dns\_zone\_ids](#input\_web\_app\_routing\_dns\_zone\_ids)

Description: The web app routing DNS zone IDs for the Kubernetes cluster.

Type: `map(list(string))`

Default: `{}`

### <a name="input_windows_profile"></a> [windows\_profile](#input\_windows\_profile)

Description: The Windows profile for the Kubernetes cluster.

Type:

```hcl
object({
    admin_username = string
    admin_password = string
    license        = optional(string)
    gmsa = optional(object({
      root_domain = string
      dns_server  = string
    }))
  })
```

Default: `null`

### <a name="input_workload_autoscaler_profile"></a> [workload\_autoscaler\_profile](#input\_workload\_autoscaler\_profile)

Description: The workload autoscaler profile for the Kubernetes cluster.

Type:

```hcl
object({
    keda_enabled = optional(bool)
    vpa_enabled  = optional(bool)
  })
```

Default: `null`

### <a name="input_workload_identity_enabled"></a> [workload\_identity\_enabled](#input\_workload\_identity\_enabled)

Description: Whether or not workload identity is enabled for the Kubernetes cluster.

Type: `bool`

Default: `false`

## Outputs

The following outputs are exported:

### <a name="output_name"></a> [name](#output\_name)

Description: Name of the Kubernetes cluster.

### <a name="output_nodepool_resource_ids"></a> [nodepool\_resource\_ids](#output\_nodepool\_resource\_ids)

Description: A map of nodepool keys to resource ids.

### <a name="output_private_endpoints"></a> [private\_endpoints](#output\_private\_endpoints)

Description:   A map of the private endpoints created.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: Resource ID of the Kubernetes cluster.

## Modules

The following Modules are called:

### <a name="module_nodepools"></a> [nodepools](#module\_nodepools)

Source: ./modules/nodepool

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->