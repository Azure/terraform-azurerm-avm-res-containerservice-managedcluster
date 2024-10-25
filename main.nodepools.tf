resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = var.node_pools != null ? { for pool in var.node_pools : pool.name => pool } : {}

  kubernetes_cluster_id         = azurerm_kubernetes_cluster.this.id
  name                          = each.value.name
  vm_size                       = each.value.vm_size
  auto_scaling_enabled          = each.value.auto_scaling_enabled
  capacity_reservation_group_id = each.value.capacity_reservation_group_id
  eviction_policy               = each.value.eviction_policy
  fips_enabled                  = each.value.fips_enabled
  gpu_instance                  = each.value.gpu_instance
  host_encryption_enabled       = each.value.host_encryption_enabled
  host_group_id                 = each.value.host_group_id
  kubelet_disk_type             = each.value.kubelet_disk_type
  max_count                     = each.value.max_count
  max_pods                      = each.value.max_pods
  min_count                     = each.value.min_count
  mode                          = each.value.mode
  node_count                    = each.value.node_count
  node_labels                   = each.value.node_labels
  node_public_ip_enabled        = each.value.node_public_ip_enabled
  node_public_ip_prefix_id      = each.value.node_public_ip_prefix_id
  node_taints                   = each.value.node_taints
  orchestrator_version          = each.value.orchestrator_version
  os_disk_size_gb               = each.value.os_disk_size_gb
  os_disk_type                  = each.value.os_disk_type
  os_sku                        = each.value.os_sku
  os_type                       = each.value.os_type
  pod_subnet_id                 = each.value.pod_subnet_id
  priority                      = each.value.priority
  proximity_placement_group_id  = each.value.proximity_placement_group_id
  scale_down_mode               = each.value.scale_down_mode
  snapshot_id                   = each.value.snapshot_id
  spot_max_price                = each.value.spot_max_price
  tags                          = each.value.tags
  ultra_ssd_enabled             = each.value.ultra_ssd_enabled
  vnet_subnet_id                = each.value.vnet_subnet_id
  workload_runtime              = each.value.workload_runtime
  zones                         = each.value.zones

  dynamic "kubelet_config" {
    for_each = each.value.kubelet_config != null ? [each.value.kubelet_config] : []

    content {
      allowed_unsafe_sysctls    = kubelet_config.value.allowed_unsafe_sysctls
      container_log_max_line    = kubelet_config.value.container_log_max_line
      container_log_max_size_mb = kubelet_config.value.container_log_max_size_mb
      cpu_cfs_quota_enabled     = kubelet_config.value.cpu_cfs_quota_enabled
      cpu_cfs_quota_period      = kubelet_config.value.cpu_cfs_quota_period
      cpu_manager_policy        = kubelet_config.value.cpu_manager_policy
      image_gc_high_threshold   = kubelet_config.value.image_gc_high_threshold
      image_gc_low_threshold    = kubelet_config.value.image_gc_low_threshold
      pod_max_pid               = kubelet_config.value.pod_max_pid
      topology_manager_policy   = kubelet_config.value.topology_manager_policy
    }
  }
  dynamic "linux_os_config" {
    for_each = each.value.linux_os_config != null ? [each.value.linux_os_config] : []

    content {
      swap_file_size_mb             = linux_os_config.value.swap_file_size_mb
      transparent_huge_page_defrag  = linux_os_config.value.transparent_huge_page_defrag
      transparent_huge_page_enabled = linux_os_config.value.transparent_huge_page_enabled

      dynamic "sysctl_config" {
        for_each = each.value.linux_os_config.sysctl_config != null ? [each.value.linux_os_config.sysctl_config] : []

        content {
          fs_aio_max_nr                      = sysctl_config.value.fs_aio_max_nr
          fs_file_max                        = sysctl_config.value.fs_file_max
          fs_inotify_max_user_watches        = sysctl_config.value.fs_inotify_max_user_watches
          fs_nr_open                         = sysctl_config.value.fs_nr_open
          kernel_threads_max                 = sysctl_config.value.kernel_threads_max
          net_core_netdev_max_backlog        = sysctl_config.value.net_core_netdev_max_backlog
          net_core_optmem_max                = sysctl_config.value.net_core_optmem_max
          net_core_rmem_default              = sysctl_config.value.net_core_rmem_default
          net_core_rmem_max                  = sysctl_config.value.net_core_rmem_max
          net_core_somaxconn                 = sysctl_config.value.net_core_somaxconn
          net_core_wmem_default              = sysctl_config.value.net_core_wmem_default
          net_core_wmem_max                  = sysctl_config.value.net_core_wmem_max
          net_ipv4_ip_local_port_range_max   = sysctl_config.value.net_ipv4_ip_local_port_range_max
          net_ipv4_ip_local_port_range_min   = sysctl_config.value.net_ipv4_ip_local_port_range_min
          net_ipv4_neigh_default_gc_thresh1  = sysctl_config.value.net_ipv4_neigh_default_gc_thresh1
          net_ipv4_neigh_default_gc_thresh2  = sysctl_config.value.net_ipv4_neigh_default_gc_thresh2
          net_ipv4_neigh_default_gc_thresh3  = sysctl_config.value.net_ipv4_neigh_default_gc_thresh3
          net_ipv4_tcp_fin_timeout           = sysctl_config.value.net_ipv4_tcp_fin_timeout
          net_ipv4_tcp_keepalive_intvl       = sysctl_config.value.net_ipv4_tcp_keepalive_intvl
          net_ipv4_tcp_keepalive_probes      = sysctl_config.value.net_ipv4_tcp_keepalive_probes
          net_ipv4_tcp_keepalive_time        = sysctl_config.value.net_ipv4_tcp_keepalive_time
          net_ipv4_tcp_max_syn_backlog       = sysctl_config.value.net_ipv4_tcp_max_syn_backlog
          net_ipv4_tcp_max_tw_buckets        = sysctl_config.value.net_ipv4_tcp_max_tw_buckets
          net_ipv4_tcp_tw_reuse              = sysctl_config.value.net_ipv4_tcp_tw_reuse
          net_netfilter_nf_conntrack_buckets = sysctl_config.value.net_netfilter_nf_conntrack_buckets
          net_netfilter_nf_conntrack_max     = sysctl_config.value.net_netfilter_nf_conntrack_max
          vm_max_map_count                   = sysctl_config.value.vm_max_map_count
          vm_swappiness                      = sysctl_config.value.vm_swappiness
          vm_vfs_cache_pressure              = sysctl_config.value.vm_vfs_cache_pressure
        }
      }
    }
  }
  dynamic "node_network_profile" {
    for_each = each.value.node_network_profile != null ? [each.value.node_network_profile] : []

    content {
      application_security_group_ids = each.value.node_network_profile.application_security_group_ids
      node_public_ip_tags            = each.value.node_network_profile.node_public_ip_tags

      dynamic "allowed_host_ports" {
        for_each = each.value.node_network_profile.allowed_host_ports != null ? [each.value.node_network_profile.allowed_host_ports] : []

        content {
          port_end   = allowed_host_ports.value.port_end
          port_start = allowed_host_ports.value.port_start
          protocol   = allowed_host_ports.value.protocol
        }
      }
    }
  }
  dynamic "upgrade_settings" {
    for_each = each.value.upgrade_settings != null ? [each.value.upgrade_settings] : []

    content {
      max_surge                     = upgrade_settings.value.max_surge
      drain_timeout_in_minutes      = upgrade_settings.value.drain_timeout_in_minutes
      node_soak_duration_in_minutes = upgrade_settings.value.node_soak_duration_in_minutes
    }
  }
  dynamic "windows_profile" {
    for_each = each.value.windows_profile != null ? [each.value.windows_profile] : []

    content {
      outbound_nat_enabled = windows_profile.value.outbound_nat_enabled
    }
  }
}
