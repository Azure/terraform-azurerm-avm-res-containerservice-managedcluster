<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-containerservice-managedcluster//nodepool

Module to deploy AKS nodepools.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 4.0.0, < 5.0.0)

## Resources

The following resources are used by this module:

- [azurerm_kubernetes_cluster_node_pool.create_before_destroy_node_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) (resource)
- [azurerm_kubernetes_cluster_node_pool.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) (resource)
- [terraform_data.pool_name_keeper](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_cluster_resource_id"></a> [cluster\_resource\_id](#input\_cluster\_resource\_id)

Description: Resource ID of the existing Kubernetes cluster.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: Required. The name of the Kubernetes nodepool.

Type: `string`

### <a name="input_network_plugin_mode"></a> [network\_plugin\_mode](#input\_network\_plugin\_mode)

Description: The network plugin mode for the nodepool.

Type: `string`

### <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size)

Description: Required. The size of the VMs for the nodepool.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_auto_scaling_enabled"></a> [auto\_scaling\_enabled](#input\_auto\_scaling\_enabled)

Description: Optional. Whether or not auto-scaling is enabled.

Type: `bool`

Default: `false`

### <a name="input_capacity_reservation_group_id"></a> [capacity\_reservation\_group\_id](#input\_capacity\_reservation\_group\_id)

Description: The ID of the capacity reservation group.

Type: `string`

Default: `null`

### <a name="input_create_nodepool_before_destroy"></a> [create\_nodepool\_before\_destroy](#input\_create\_nodepool\_before\_destroy)

Description: Whether or not to create node pools before destroying the old ones. This is the opposite of the default behavior. Set this to true if zero downtime is required during nodepool redeployments such as changes to snapshot\_id.

Type: `bool`

Default: `false`

### <a name="input_eviction_policy"></a> [eviction\_policy](#input\_eviction\_policy)

Description: Optional. The eviction policy for the nodepool.

Type: `string`

Default: `null`

### <a name="input_fips_enabled"></a> [fips\_enabled](#input\_fips\_enabled)

Description: Optional. Whether or not FIPS is enabled.

Type: `bool`

Default: `null`

### <a name="input_gpu_instance"></a> [gpu\_instance](#input\_gpu\_instance)

Description: Optional. The GPU instance type for the nodepool.

Type: `string`

Default: `null`

### <a name="input_host_encryption_enabled"></a> [host\_encryption\_enabled](#input\_host\_encryption\_enabled)

Description: Optional. Whether or not host encryption is enabled.

Type: `bool`

Default: `null`

### <a name="input_host_group_id"></a> [host\_group\_id](#input\_host\_group\_id)

Description: Optional. The ID of the host group.

Type: `string`

Default: `null`

### <a name="input_kubelet_config"></a> [kubelet\_config](#input\_kubelet\_config)

Description: Optional. The Kubelet config for the nodepool.

Type:

```hcl
object({
    cpu_manager_policy        = string
    cpu_cfs_quota_enabled     = bool
    cpu_cfs_quota_period      = string
    image_gc_high_threshold   = number
    image_gc_low_threshold    = number
    topology_manager_policy   = string
    allowed_unsafe_sysctls    = set(string)
    container_log_max_size_mb = number
    container_log_max_line    = number
    pod_max_pid               = number
  })
```

Default: `null`

### <a name="input_kubelet_disk_type"></a> [kubelet\_disk\_type](#input\_kubelet\_disk\_type)

Description: Optional. The disk type for the kubelet.

Type: `string`

Default: `null`

### <a name="input_linux_os_config"></a> [linux\_os\_config](#input\_linux\_os\_config)

Description: Optional. The Linux OS config for the nodepool.

Type:

```hcl
object({
    swap_file_size_mb             = optional(number)
    transparent_huge_page_defrag  = optional(string)
    transparent_huge_page_enabled = optional(string)
    sysctl_config = object({
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
    })
  })
```

Default: `null`

### <a name="input_max_count"></a> [max\_count](#input\_max\_count)

Description: Optional. The maximum number of nodes for the nodepool if auto-scaling is enabled.

Type: `number`

Default: `null`

### <a name="input_max_pods"></a> [max\_pods](#input\_max\_pods)

Description: Optional. The maximum number of pods per node.

Type: `number`

Default: `null`

### <a name="input_min_count"></a> [min\_count](#input\_min\_count)

Description: Optional. The minimum number of nodes for the nodepool if auto-scaling is enabled.

Type: `number`

Default: `null`

### <a name="input_mode"></a> [mode](#input\_mode)

Description: Optional. The mode for the nodepool.

Type: `string`

Default: `null`

### <a name="input_node_count"></a> [node\_count](#input\_node\_count)

Description: Optional. The number of nodes for the nodepool. Set to 0 if auto-scaling is enabled.

Type: `number`

Default: `null`

### <a name="input_node_labels"></a> [node\_labels](#input\_node\_labels)

Description: Optional. The labels for the nodepool.

Type: `map(string)`

Default: `null`

### <a name="input_node_network_profile"></a> [node\_network\_profile](#input\_node\_network\_profile)

Description: Optional. The network profile for the nodepool.

Type:

```hcl
object({
    allowed_host_ports = list(object({
      port_start = number
      port_end   = number
      protocol   = string
    }))
    application_security_group_ids = list(string)
    node_public_ip_tags            = map(string)
  })
```

Default: `null`

### <a name="input_node_public_ip_enabled"></a> [node\_public\_ip\_enabled](#input\_node\_public\_ip\_enabled)

Description: Optional. Whether or not public IPs are enabled for the nodepool.

Type: `bool`

Default: `null`

### <a name="input_node_public_ip_prefix_id"></a> [node\_public\_ip\_prefix\_id](#input\_node\_public\_ip\_prefix\_id)

Description: Optional. The ID of the public IP prefix.

Type: `string`

Default: `null`

### <a name="input_node_taints"></a> [node\_taints](#input\_node\_taints)

Description: Optional. The taints for the nodepool.

Type: `list(string)`

Default: `null`

### <a name="input_orchestrator_version"></a> [orchestrator\_version](#input\_orchestrator\_version)

Description: Optional. The Kubernetes version for the nodepool.

Type: `string`

Default: `null`

### <a name="input_os_disk_size_gb"></a> [os\_disk\_size\_gb](#input\_os\_disk\_size\_gb)

Description: Optional. The size of the OS disk for the nodepool.

Type: `number`

Default: `null`

### <a name="input_os_disk_type"></a> [os\_disk\_type](#input\_os\_disk\_type)

Description: Optional. The type of the OS disk for the nodepool.

Type: `string`

Default: `null`

### <a name="input_os_sku"></a> [os\_sku](#input\_os\_sku)

Description: Optional. The SKU of the OS for the nodepool.

Type: `string`

Default: `null`

### <a name="input_os_type"></a> [os\_type](#input\_os\_type)

Description: Optional. The type of the OS for the nodepool.

Type: `string`

Default: `null`

### <a name="input_pod_subnet_id"></a> [pod\_subnet\_id](#input\_pod\_subnet\_id)

Description: Optional. The ID of the pod subnet.

Type: `string`

Default: `null`

### <a name="input_priority"></a> [priority](#input\_priority)

Description: Optional. The priority for the nodepool.

Type: `string`

Default: `null`

### <a name="input_proximity_placement_group_id"></a> [proximity\_placement\_group\_id](#input\_proximity\_placement\_group\_id)

Description: Optional. The ID of the proximity placement group.

Type: `string`

Default: `null`

### <a name="input_scale_down_mode"></a> [scale\_down\_mode](#input\_scale\_down\_mode)

Description: Optional. The scale down mode for the nodepool.

Type: `string`

Default: `null`

### <a name="input_snapshot_id"></a> [snapshot\_id](#input\_snapshot\_id)

Description: Optional. The ID of the snapshot.

Type: `string`

Default: `null`

### <a name="input_spot_max_price"></a> [spot\_max\_price](#input\_spot\_max\_price)

Description: Optional. The maximum price for spot instances.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Optional. A mapping of tags to assign to the resource.

Type: `map(string)`

Default: `null`

### <a name="input_temporary_name_for_rotation"></a> [temporary\_name\_for\_rotation](#input\_temporary\_name\_for\_rotation)

Description: Optional. Specifies the name of the temporary node pool used to cycle the node pool when one of the relevant properties are updated.

Type: `string`

Default: `null`

### <a name="input_timeouts"></a> [timeouts](#input\_timeouts)

Description: - `create` - (Defaults to 60 minutes) Used when creating the Kubernetes Cluster Node Pool.
- `delete` - (Defaults to 60 minutes) Used when deleting the Kubernetes Cluster Node Pool.
- `read` - (Defaults to 5 minutes) Used when retrieving the Kubernetes Cluster Node Pool.
- `update` - (Defaults to 60 minutes) Used when updating the Kubernetes Cluster Node Pool.

Type:

```hcl
object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
```

Default: `null`

### <a name="input_ultra_ssd_enabled"></a> [ultra\_ssd\_enabled](#input\_ultra\_ssd\_enabled)

Description: Optional. Whether or not ultra SSD is enabled.

Type: `bool`

Default: `null`

### <a name="input_upgrade_settings"></a> [upgrade\_settings](#input\_upgrade\_settings)

Description: Optional. The upgrade settings for the nodepool.

Type:

```hcl
object({
    drain_timeout_in_minutes      = optional(number)
    node_soak_duration_in_minutes = optional(number)
    max_surge                     = optional(string)
  })
```

Default:

```json
{
  "max_surge": "10%"
}
```

### <a name="input_vnet_subnet_id"></a> [vnet\_subnet\_id](#input\_vnet\_subnet\_id)

Description: Optional. The ID of the VNet subnet.

Type: `string`

Default: `null`

### <a name="input_windows_profile"></a> [windows\_profile](#input\_windows\_profile)

Description: Optional. The Windows profile for the nodepool.

Type:

```hcl
object({
    outbound_nat_enabled = bool
  })
```

Default: `null`

### <a name="input_workload_runtime"></a> [workload\_runtime](#input\_workload\_runtime)

Description: Optional. The workload runtime for the nodepool.

Type: `string`

Default: `null`

### <a name="input_zones"></a> [zones](#input\_zones)

Description: Optional. The availability zones for the nodepool.

Type: `list(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_name"></a> [name](#output\_name)

Description: Name of the Kubernetes cluster.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: Resource ID of the Kubernetes cluster.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->