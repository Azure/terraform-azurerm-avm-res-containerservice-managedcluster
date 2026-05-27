locals {
  replace_triggers_refs = [
    "properties.vmSize",
  ]
  resource_body = {
    properties = {
      artifactStreamingProfile = var.artifact_streaming_profile == null ? null : {
        enabled = var.artifact_streaming_profile.enabled
      }
      availabilityZones          = var.availability_zones == null ? null : [for item in var.availability_zones : item]
      capacityReservationGroupID = var.capacity_reservation_group_id
      count                      = var.max_count != null && var.min_count != null ? null : var.count_of
      creationData = var.creation_data == null ? null : {
        sourceResourceId = var.creation_data.source_resource_id
      }
      enableAutoScaling       = var.enable_auto_scaling
      enableEncryptionAtHost  = var.enable_encryption_at_host
      enableFIPS              = var.enable_fips
      enableNodePublicIP      = var.enable_node_public_ip
      enableOSDiskFullCaching = var.enable_os_disk_full_caching
      enableUltraSSD          = var.enable_ultra_ssd
      gatewayProfile = var.gateway_profile == null ? null : {
        publicIPPrefixSize = var.gateway_profile.public_ip_prefix_size
      }
      gpuInstanceProfile = var.gpu_instance_profile
      gpuProfile = var.gpu_profile == null ? null : {
        driver     = var.gpu_profile.driver
        driverType = var.gpu_profile.driver_type
        nvidia = var.gpu_profile.nvidia == null ? null : {
          managementMode = var.gpu_profile.nvidia.management_mode
          migStrategy    = var.gpu_profile.nvidia.mig_strategy
        }
      }
      hostGroupID = var.host_group_id
      kubeletConfig = var.kubelet_config == null ? null : {
        allowedUnsafeSysctls  = var.kubelet_config.allowed_unsafe_sysctls == null ? null : [for item in var.kubelet_config.allowed_unsafe_sysctls : item]
        containerLogMaxFiles  = var.kubelet_config.container_log_max_files
        containerLogMaxSizeMB = var.kubelet_config.container_log_max_size_mb
        cpuCfsQuota           = var.kubelet_config.cpu_cfs_quota
        cpuCfsQuotaPeriod     = var.kubelet_config.cpu_cfs_quota_period
        cpuManagerPolicy      = var.kubelet_config.cpu_manager_policy
        failSwapOn            = var.kubelet_config.fail_swap_on
        imageGcHighThreshold  = var.kubelet_config.image_gc_high_threshold
        imageGcLowThreshold   = var.kubelet_config.image_gc_low_threshold
        podMaxPids            = var.kubelet_config.pod_max_pids
        seccompDefault        = var.kubelet_config.seccomp_default
        topologyManagerPolicy = var.kubelet_config.topology_manager_policy
      }
      kubeletDiskType = var.kubelet_disk_type
      linuxOSConfig = var.linux_os_config == null ? null : {
        swapFileSizeMB = var.linux_os_config.swap_file_size_mb
        sysctls = var.linux_os_config.sysctls == null ? null : {
          fsAioMaxNr                     = var.linux_os_config.sysctls.fs_aio_max_nr
          fsFileMax                      = var.linux_os_config.sysctls.fs_file_max
          fsInotifyMaxUserWatches        = var.linux_os_config.sysctls.fs_inotify_max_user_watches
          fsNrOpen                       = var.linux_os_config.sysctls.fs_nr_open
          kernelThreadsMax               = var.linux_os_config.sysctls.kernel_threads_max
          netCoreNetdevMaxBacklog        = var.linux_os_config.sysctls.net_core_netdev_max_backlog
          netCoreOptmemMax               = var.linux_os_config.sysctls.net_core_optmem_max
          netCoreRmemDefault             = var.linux_os_config.sysctls.net_core_rmem_default
          netCoreRmemMax                 = var.linux_os_config.sysctls.net_core_rmem_max
          netCoreSomaxconn               = var.linux_os_config.sysctls.net_core_somaxconn
          netCoreWmemDefault             = var.linux_os_config.sysctls.net_core_wmem_default
          netCoreWmemMax                 = var.linux_os_config.sysctls.net_core_wmem_max
          netIpv4IpLocalPortRange        = var.linux_os_config.sysctls.net_ipv4_ip_local_port_range
          netIpv4NeighDefaultGcThresh1   = var.linux_os_config.sysctls.net_ipv4_neigh_default_gc_thresh1
          netIpv4NeighDefaultGcThresh2   = var.linux_os_config.sysctls.net_ipv4_neigh_default_gc_thresh2
          netIpv4NeighDefaultGcThresh3   = var.linux_os_config.sysctls.net_ipv4_neigh_default_gc_thresh3
          netIpv4TcpFinTimeout           = var.linux_os_config.sysctls.net_ipv4_tcp_fin_timeout
          netIpv4TcpKeepaliveProbes      = var.linux_os_config.sysctls.net_ipv4_tcp_keepalive_probes
          netIpv4TcpKeepaliveTime        = var.linux_os_config.sysctls.net_ipv4_tcp_keepalive_time
          netIpv4TcpMaxSynBacklog        = var.linux_os_config.sysctls.net_ipv4_tcp_max_syn_backlog
          netIpv4TcpMaxTwBuckets         = var.linux_os_config.sysctls.net_ipv4_tcp_max_tw_buckets
          netIpv4TcpTwReuse              = var.linux_os_config.sysctls.net_ipv4_tcp_tw_reuse
          netIpv4TcpkeepaliveIntvl       = var.linux_os_config.sysctls.net_ipv4_tcpkeepalive_intvl
          netNetfilterNfConntrackBuckets = var.linux_os_config.sysctls.net_netfilter_nf_conntrack_buckets
          netNetfilterNfConntrackMax     = var.linux_os_config.sysctls.net_netfilter_nf_conntrack_max
          vmMaxMapCount                  = var.linux_os_config.sysctls.vm_max_map_count
          vmSwappiness                   = var.linux_os_config.sysctls.vm_swappiness
          vmVfsCachePressure             = var.linux_os_config.sysctls.vm_vfs_cache_pressure
        }
        transparentHugePageDefrag  = var.linux_os_config.transparent_huge_page_defrag
        transparentHugePageEnabled = var.linux_os_config.transparent_huge_page_enabled
      }
      localDNSProfile = var.local_dns_profile == null ? null : {
        kubeDNSOverrides = var.local_dns_profile.kube_dns_overrides == null ? null : { for k, value in var.local_dns_profile.kube_dns_overrides : k => value == null ? null : {
          cacheDurationInSeconds      = value.cache_duration_in_seconds
          forwardDestination          = value.forward_destination
          forwardPolicy               = value.forward_policy
          maxConcurrent               = value.max_concurrent
          protocol                    = value.protocol
          queryLogging                = value.query_logging
          serveStale                  = value.serve_stale
          serveStaleDurationInSeconds = value.serve_stale_duration_in_seconds
        } }
        mode  = var.local_dns_profile.mode
        state = var.local_dns_profile.state
        vnetDNSOverrides = var.local_dns_profile.vnet_dns_overrides == null ? null : { for k, value in var.local_dns_profile.vnet_dns_overrides : k => value == null ? null : {
          cacheDurationInSeconds      = value.cache_duration_in_seconds
          forwardDestination          = value.forward_destination
          forwardPolicy               = value.forward_policy
          maxConcurrent               = value.max_concurrent
          protocol                    = value.protocol
          queryLogging                = value.query_logging
          serveStale                  = value.serve_stale
          serveStaleDurationInSeconds = value.serve_stale_duration_in_seconds
        } }
      }
      maxCount        = var.max_count
      maxPods         = var.max_pods
      messageOfTheDay = var.message_of_the_day
      minCount        = var.min_count
      mode            = var.mode
      networkProfile = var.network_profile == null ? null : {
        allowedHostPorts = var.network_profile.allowed_host_ports == null ? null : [for item in var.network_profile.allowed_host_ports : item == null ? null : {
          portEnd   = item.port_end
          portStart = item.port_start
          protocol  = item.protocol
        }]
        applicationSecurityGroups = var.network_profile.application_security_groups == null ? null : [for item in var.network_profile.application_security_groups : item]
        nodePublicIPTags = var.network_profile.node_public_ip_tags == null ? null : [for item in var.network_profile.node_public_ip_tags : item == null ? null : {
          ipTagType = item.ip_tag_type
          tag       = item.tag
        }]
      }
      nodeLabels = var.node_labels == null ? null : { for k, value in var.node_labels : k => value }
      nodeCustomizationProfile = var.node_customization_profile == null ? null : {
        nodeCustomizationId = var.node_customization_profile.node_customization_id
      }
      nodeImageVersion          = var.node_image_version
      nodeInitializationTaints  = var.node_initialization_taints == null ? null : [for item in var.node_initialization_taints : item]
      nodePublicIPPrefixID      = var.node_public_ip_prefix_id
      nodeTaints                = var.node_taints == null ? null : [for item in var.node_taints : item]
      orchestratorVersion       = var.orchestrator_version
      osDiskSizeGB              = var.os_disk_size_gb
      osDiskType                = var.os_disk_type
      osSKU                     = var.os_sku
      osType                    = var.os_type
      podIPAllocationMode       = var.pod_ip_allocation_mode
      podSubnetID               = var.pod_subnet_id
      proximityPlacementGroupID = var.proximity_placement_group_id
      scaleDownMode             = var.scale_down_mode
      scaleSetEvictionPolicy    = var.scale_set_eviction_policy
      scaleSetPriority          = var.scale_set_priority
      securityProfile = var.security_profile == null ? null : {
        enableSecureBoot = var.security_profile.enable_secure_boot
        enableVTPM       = var.security_profile.enable_vtpm
        sshAccess        = var.security_profile.ssh_access
      }
      spotMaxPrice = var.spot_max_price
      tags         = var.tags == null ? null : { for k, value in var.tags : k => value }
      type         = var.type
      upgradeSettings = var.upgrade_settings == null ? null : {
        drainTimeoutInMinutes     = var.upgrade_settings.drain_timeout_in_minutes
        maxBlockedNodes           = var.upgrade_settings.max_blocked_nodes
        maxSurge                  = var.upgrade_settings.max_surge
        maxUnavailable            = var.upgrade_settings.max_unavailable
        nodeSoakDurationInMinutes = var.upgrade_settings.node_soak_duration_in_minutes
        undrainableNodeBehavior   = var.upgrade_settings.undrainable_node_behavior
      }
      upgradeSettingsBlueGreen = var.upgrade_settings_blue_green == null ? null : {
        batchSoakDurationInMinutes = var.upgrade_settings_blue_green.batch_soak_duration_in_minutes
        drainBatchSize             = var.upgrade_settings_blue_green.drain_batch_size
        drainTimeoutInMinutes      = var.upgrade_settings_blue_green.drain_timeout_in_minutes
        finalSoakDurationInMinutes = var.upgrade_settings_blue_green.final_soak_duration_in_minutes
      }
      upgradeStrategy = var.upgrade_strategy
      virtualMachinesProfile = var.virtual_machines_profile == null ? null : {
        scale = var.virtual_machines_profile.scale == null ? null : {
          manual = var.virtual_machines_profile.scale.manual == null ? null : [for item in var.virtual_machines_profile.scale.manual : item == null ? null : {
            count = item.count
            size  = item.size
          }]
        }
      }
      vmSize       = var.vm_size
      vnetSubnetID = var.vnet_subnet_id
      windowsProfile = var.windows_profile == null ? null : {
        disableOutboundNat = var.windows_profile.disable_outbound_nat
      }
      workloadRuntime = var.workload_runtime
    }
  }
}
