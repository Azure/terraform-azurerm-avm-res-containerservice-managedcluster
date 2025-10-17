#############################################
# Node Pool via AzAPI (Microsoft.ContainerService/managedClusters/agentPools)
# Converted from azurerm_kubernetes_cluster_node_pool to azapi_resource
# NOTE: `temporary_name_for_rotation` cannot be expressed directly with the
# ARM API; create_before_destroy logic is implemented explicitly when
# var.create_nodepool_before_destroy = true.
#############################################

# State migration mapping from former azurerm resources to azapi resources.
# These allow 'terraform plan' to adopt existing state without destroy/recreate.
moved {
  from = azurerm_kubernetes_cluster_node_pool.this[0]
  to   = azapi_resource.this[0]
}

moved {
  from = azurerm_kubernetes_cluster_node_pool.create_before_destroy_node_pool[0]
  to   = azapi_resource.create_before_destroy_node_pool[0]
}

locals {
  agent_pool_properties = { for k, v in local.agent_pool_properties_base : k => v if v != null }
  agent_pool_properties_base = {
    vmSize                     = var.vm_size
    enableAutoScaling          = var.auto_scaling_enabled
    capacityReservationGroupID = var.capacity_reservation_group_id
    scaleSetEvictionPolicy     = var.eviction_policy
    enableFIPS                 = var.fips_enabled
    gpuInstanceProfile         = var.gpu_instance
    enableEncryptionAtHost     = var.host_encryption_enabled
    hostGroupID                = var.host_group_id
    kubeletDiskType            = var.kubelet_disk_type
    maxCount                   = var.max_count
    maxPods                    = var.max_pods
    minCount                   = var.min_count
    mode                       = var.mode
    count                      = var.node_count
    nodeLabels                 = var.node_labels
    enableNodePublicIP         = var.node_public_ip_enabled
    nodePublicIPPrefixID       = var.node_public_ip_prefix_id
    nodeTaints                 = var.node_taints
    orchestratorVersion        = var.orchestrator_version
    osDiskSizeGB               = var.os_disk_size_gb
    osDiskType                 = var.os_disk_type
    osSKU                      = var.os_sku
    osType                     = var.os_type
    podSubnetID                = var.pod_subnet_id
    scaleSetPriority           = var.priority
    proximityPlacementGroupID  = var.proximity_placement_group_id
    scaleDownMode              = var.scale_down_mode
    creationData               = local.creation_data_map
    spotMaxPrice               = var.spot_max_price
    enableUltraSSD             = var.ultra_ssd_enabled
    vnetSubnetID               = var.vnet_subnet_id
    workloadRuntime            = var.workload_runtime
    availabilityZones          = var.zones
    upgradeSettings            = local.upgrade_settings_map
    windowsProfile             = local.windows_profile_map
    networkProfile             = local.network_profile_map
    kubeletConfig              = local.kubelet_config_map
    linuxOSConfig              = local.linux_os_config_map
  }
  creation_data_map = var.snapshot_id == null ? null : {
    sourceResourceId = var.snapshot_id
  }
  kubelet_config_map = var.kubelet_config == null ? null : {
    cpuManagerPolicy      = var.kubelet_config.cpu_manager_policy
    cpuCfsQuota           = var.kubelet_config.cpu_cfs_quota_enabled
    cpuCfsQuotaPeriod     = var.kubelet_config.cpu_cfs_quota_period
    imageGcHighThreshold  = var.kubelet_config.image_gc_high_threshold
    imageGcLowThreshold   = var.kubelet_config.image_gc_low_threshold
    topologyManagerPolicy = var.kubelet_config.topology_manager_policy
    allowedUnsafeSysctls  = length(var.kubelet_config.allowed_unsafesysctls_base) == 0 ? null : var.kubelet_config.allowed_unsafesysctls_base
    containerLogMaxSizeMB = var.kubelet_config.container_log_max_size_mb
    containerLogMaxFiles  = var.kubelet_config.container_log_max_line
    podMaxPids            = var.kubelet_config.pod_max_pid
  }
  linux_os_config_map = var.linux_os_config == null ? null : {
    swapFileSizeMB             = var.linux_os_config.swap_file_size_mb
    transparentHugePageDefrag  = var.linux_os_config.transparent_huge_page_defrag
    transparentHugePageEnabled = var.linux_os_config.transparent_huge_page_enabled
    sysctls                    = length(local.sysctls) == 0 ? null : local.sysctls
  }
  network_profile_map = var.node_network_profile == null ? null : {
    applicationSecurityGroups = var.node_network_profile.application_security_group_ids
    nodePublicIPTags          = var.node_network_profile.node_public_ip_tags
    allowedHostPorts = length(var.node_network_profile.allowed_host_ports) == 0 ? null : [for p in var.node_network_profile.allowed_host_ports : {
      portStart = p.port_start
      portEnd   = p.port_end
      protocol  = p.protocol
    }]
  }
  sysctls = { for k, v in local.sysctls_base : k => v if v != null }
  # Build sysctls map (filter out nulls) combining min/max port range if both provided
  sysctls_base = var.linux_os_config == null || var.linux_os_config.sysctl_config == null ? {} : {
    fsAioMaxNr              = var.linux_os_config.sysctl_config.fs_aio_max_nr
    fsFileMax               = var.linux_os_config.sysctl_config.fs_file_max
    fsInotifyMaxUserWatches = var.linux_os_config.sysctl_config.fs_inotify_max_user_watches
    fsNrOpen                = var.linux_os_config.sysctl_config.fs_nr_open
    kernelThreadsMax        = var.linux_os_config.sysctl_config.kernel_threads_max
    netCoreNetdevMaxBacklog = var.linux_os_config.sysctl_config.net_core_netdev_max_backlog
    netCoreOptmemMax        = var.linux_os_config.sysctl_config.net_core_optmem_max
    netCoreRmemDefault      = var.linux_os_config.sysctl_config.net_core_rmem_default
    netCoreRmemMax          = var.linux_os_config.sysctl_config.net_core_rmem_max
    netCoreSomaxconn        = var.linux_os_config.sysctl_config.net_core_somaxconn
    netCoreWmemDefault      = var.linux_os_config.sysctl_config.net_core_wmem_default
    netCoreWmemMax          = var.linux_os_config.sysctl_config.net_core_wmem_max
    netIpv4IpLocalPortRange = (
      var.linux_os_config.sysctl_config.net_ipv4_ip_local_port_range_min != null &&
      var.linux_os_config.sysctl_config.net_ipv4_ip_local_port_range_max != null
      ) ? (
      format("%d %d",
        var.linux_os_config.sysctl_config.net_ipv4_ip_local_port_range_min,
        var.linux_os_config.sysctl_config.net_ipv4_ip_local_port_range_max
      )
    ) : null
    netIpv4NeighDefaultGcThresh1   = var.linux_os_config.sysctl_config.net_ipv4_neigh_default_gc_thresh1
    netIpv4NeighDefaultGcThresh2   = var.linux_os_config.sysctl_config.net_ipv4_neigh_default_gc_thresh2
    netIpv4NeighDefaultGcThresh3   = var.linux_os_config.sysctl_config.net_ipv4_neigh_default_gc_thresh3
    netIpv4TcpFinTimeout           = var.linux_os_config.sysctl_config.net_ipv4_tcp_fin_timeout
    netIpv4TcpKeepaliveProbes      = var.linux_os_config.sysctl_config.net_ipv4_tcp_keepalive_probes
    netIpv4TcpkeepaliveIntvl       = var.linux_os_config.sysctl_config.net_ipv4_tcp_keepalive_intvl
    netIpv4TcpKeepaliveTime        = var.linux_os_config.sysctl_config.net_ipv4_tcp_keepalive_time
    netIpv4TcpMaxSynBacklog        = var.linux_os_config.sysctl_config.net_ipv4_tcp_max_syn_backlog
    netIpv4TcpMaxTwBuckets         = var.linux_os_config.sysctl_config.net_ipv4_tcp_max_tw_buckets
    netIpv4TcpTwReuse              = var.linux_os_config.sysctl_config.net_ipv4_tcp_tw_reuse
    netNetfilterNfConntrackBuckets = var.linux_os_config.sysctl_config.net_netfilter_nf_conntrack_buckets
    netNetfilterNfConntrackMax     = var.linux_os_config.sysctl_config.net_netfilter_nf_conntrack_max
    vmMaxMapCount                  = var.linux_os_config.sysctl_config.vm_max_map_count
    vmSwappiness                   = var.linux_os_config.sysctl_config.vm_swappiness
    vmVfsCachePressure             = var.linux_os_config.sysctl_config.vm_vfs_cache_pressure
  }
  upgrade_settings_map = var.upgrade_settings == null ? null : {
    maxSurge                  = var.upgrade_settings.max_surge
    drainTimeoutInMinutes     = var.upgrade_settings.drain_timeout_in_minutes
    nodeSoakDurationInMinutes = var.upgrade_settings.node_soak_duration_in_minutes
  }
  windows_profile_map = var.windows_profile == null ? null : {
    # API property is disableOutboundNat (inverse of outbound_nat_enabled)
    disableOutboundNat = var.windows_profile.outbound_nat_enabled == null ? null : (!var.windows_profile.outbound_nat_enabled)
  }
}

resource "azapi_resource" "this" {
  count = var.create_nodepool_before_destroy ? 0 : 1

  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.ContainerService/managedClusters/agentPools@2025-07-01"
  body = merge({
    properties = local.agent_pool_properties
  }, var.tags == null ? {} : { tags = var.tags })
  ignore_null_property      = true
  response_export_values    = []
  schema_validation_enabled = false

  timeouts {
    create = try(var.timeouts.create, null)
    delete = try(var.timeouts.delete, null)
    read   = try(var.timeouts.read, null)
    update = try(var.timeouts.update, null)
  }

  lifecycle {
    precondition {
      condition     = var.network_plugin_mode != "overlay" || !can(regex("^Standard_DC[0-9]+s?_v2$", var.vm_size))
      error_message = "With with Azure CNI Overlay you can't use DCsv2-series virtual machines in node pools. "
    }
    precondition {
      condition     = var.auto_scaling_enabled || var.node_count != null
      error_message = "Either auto_scaling_enabled or node_count must be set."
    }
    precondition {
      condition     = !(var.eviction_policy != null) || var.priority == "Spot"
      error_message = "Eviction policy can only be set when priority is set to 'Spot'."
    }
  }
  tags = var.tags

  replace_triggers_refs = [
    "properties.vmSize",
  ]
}

resource "azapi_resource" "create_before_destroy_node_pool" {
  count = var.create_nodepool_before_destroy ? 1 : 0

  name      = "${var.name}${substr(md5(uuid()), 0, 4)}"
  parent_id = var.parent_id
  type      = "Microsoft.ContainerService/managedClusters/agentPools@2025-07-01"
  body = merge({
    properties = local.agent_pool_properties
  }, var.tags == null ? {} : { tags = var.tags })
  ignore_null_property      = true
  response_export_values    = []
  schema_validation_enabled = false

  timeouts {
    create = try(var.timeouts.create, null)
    delete = try(var.timeouts.delete, null)
    read   = try(var.timeouts.read, null)
    update = try(var.timeouts.update, null)
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
    replace_triggered_by  = [terraform_data.pool_name_keeper]

    precondition {
      condition     = var.network_plugin_mode != "overlay" || !can(regex("^Standard_DC[0-9]+s?_v2$", var.vm_size))
      error_message = "With with Azure CNI Overlay you can't use DCsv2-series virtual machines in node pools. "
    }
    precondition {
      condition     = var.auto_scaling_enabled || var.node_count != null
      error_message = "Either auto_scaling_enabled or node_count must be set."
    }
    precondition {
      condition     = !(var.eviction_policy != null) || var.priority == "Spot"
      error_message = "Eviction policy can only be set when priority is set to 'Spot'."
    }
    precondition {
      condition     = !var.create_nodepool_before_destroy || length(var.name) <= 8
      error_message = "Node pool name must be less than or equal to 8 characters if create_before_destroy is selected to prevent name conflicts."
    }
  }
  replace_triggers_refs = [
    "properties.vmSize",
  ]
  tags = var.tags
}

resource "terraform_data" "pool_name_keeper" {
  triggers_replace = {
    pool_name = var.name
  }
}
