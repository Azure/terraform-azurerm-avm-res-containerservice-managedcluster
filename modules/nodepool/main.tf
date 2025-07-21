resource "azurerm_kubernetes_cluster_node_pool" "this" {
  count = var.create_nodepool_before_destroy ? 0 : 1

  kubernetes_cluster_id         = var.cluster_resource_id
  name                          = var.name
  auto_scaling_enabled          = var.auto_scaling_enabled
  capacity_reservation_group_id = var.capacity_reservation_group_id
  eviction_policy               = var.eviction_policy
  fips_enabled                  = var.fips_enabled
  gpu_instance                  = var.gpu_instance
  host_encryption_enabled       = var.host_encryption_enabled
  host_group_id                 = var.host_group_id
  kubelet_disk_type             = var.kubelet_disk_type
  max_count                     = var.max_count
  max_pods                      = var.max_pods
  min_count                     = var.min_count
  mode                          = var.mode
  node_count                    = var.node_count
  node_labels                   = var.node_labels
  node_public_ip_enabled        = var.node_public_ip_enabled
  node_public_ip_prefix_id      = var.node_public_ip_prefix_id
  node_taints                   = var.node_taints
  orchestrator_version          = var.orchestrator_version
  os_disk_size_gb               = var.os_disk_size_gb
  os_disk_type                  = var.os_disk_type
  os_sku                        = var.os_sku
  os_type                       = var.os_type
  pod_subnet_id                 = var.pod_subnet_id
  priority                      = var.priority
  proximity_placement_group_id  = var.proximity_placement_group_id
  scale_down_mode               = var.scale_down_mode
  snapshot_id                   = var.snapshot_id
  spot_max_price                = var.spot_max_price
  tags                          = var.tags
  temporary_name_for_rotation   = var.temporary_name_for_rotation
  ultra_ssd_enabled             = var.ultra_ssd_enabled
  vm_size                       = var.vm_size
  vnet_subnet_id                = var.vnet_subnet_id
  workload_runtime              = var.workload_runtime
  zones                         = var.zones

  dynamic "kubelet_config" {
    for_each = var.kubelet_config != null ? [var.kubelet_config] : []

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
    for_each = var.linux_os_config != null ? [var.linux_os_config] : []

    content {
      swap_file_size_mb             = linux_os_config.value.swap_file_size_mb
      transparent_huge_page_defrag  = linux_os_config.value.transparent_huge_page_defrag
      transparent_huge_page_enabled = linux_os_config.value.transparent_huge_page_enabled

      dynamic "sysctl_config" {
        for_each = var.linux_os_config.sysctl_config != null ? [var.linux_os_config.sysctl_config] : []

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
    for_each = var.node_network_profile != null ? [var.node_network_profile] : []

    content {
      application_security_group_ids = var.node_network_profile.application_security_group_ids
      node_public_ip_tags            = var.node_network_profile.node_public_ip_tags

      dynamic "allowed_host_ports" {
        for_each = var.node_network_profile.allowed_host_ports != null ? [var.node_network_profile.allowed_host_ports] : []

        content {
          port_end   = allowed_host_ports.value.port_end
          port_start = allowed_host_ports.value.port_start
          protocol   = allowed_host_ports.value.protocol
        }
      }
    }
  }
  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
  dynamic "upgrade_settings" {
    for_each = var.upgrade_settings != null ? [var.upgrade_settings] : []

    content {
      max_surge                     = upgrade_settings.value.max_surge
      drain_timeout_in_minutes      = upgrade_settings.value.drain_timeout_in_minutes
      node_soak_duration_in_minutes = upgrade_settings.value.node_soak_duration_in_minutes
    }
  }
  dynamic "windows_profile" {
    for_each = var.windows_profile != null ? [var.windows_profile] : []

    content {
      outbound_nat_enabled = windows_profile.value.outbound_nat_enabled
    }
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
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "create_before_destroy_node_pool" {
  count = var.create_nodepool_before_destroy ? 1 : 0

  kubernetes_cluster_id         = var.cluster_resource_id
  name                          = "${var.name}${substr(md5(uuid()), 0, 4)}"
  auto_scaling_enabled          = var.auto_scaling_enabled
  capacity_reservation_group_id = var.capacity_reservation_group_id
  eviction_policy               = var.eviction_policy
  fips_enabled                  = var.fips_enabled
  gpu_instance                  = var.gpu_instance
  host_encryption_enabled       = var.host_encryption_enabled
  host_group_id                 = var.host_group_id
  kubelet_disk_type             = var.kubelet_disk_type
  max_count                     = var.max_count
  max_pods                      = var.max_pods
  min_count                     = var.min_count
  mode                          = var.mode
  node_count                    = var.node_count
  node_labels                   = var.node_labels
  node_public_ip_enabled        = var.node_public_ip_enabled
  node_public_ip_prefix_id      = var.node_public_ip_prefix_id
  node_taints                   = var.node_taints
  orchestrator_version          = var.orchestrator_version
  os_disk_size_gb               = var.os_disk_size_gb
  os_disk_type                  = var.os_disk_type
  os_sku                        = var.os_sku
  os_type                       = var.os_type
  pod_subnet_id                 = var.pod_subnet_id
  priority                      = var.priority
  proximity_placement_group_id  = var.proximity_placement_group_id
  scale_down_mode               = var.scale_down_mode
  snapshot_id                   = var.snapshot_id
  spot_max_price                = var.spot_max_price
  tags                          = var.tags
  temporary_name_for_rotation   = var.temporary_name_for_rotation
  ultra_ssd_enabled             = var.ultra_ssd_enabled
  vm_size                       = var.vm_size
  vnet_subnet_id                = var.vnet_subnet_id
  workload_runtime              = var.workload_runtime
  zones                         = var.zones

  dynamic "kubelet_config" {
    for_each = var.kubelet_config != null ? [var.kubelet_config] : []

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
    for_each = var.linux_os_config != null ? [var.linux_os_config] : []

    content {
      swap_file_size_mb             = linux_os_config.value.swap_file_size_mb != null ? linux_os_config.value.swap_file_size_mb : null
      transparent_huge_page_defrag  = linux_os_config.value.transparent_huge_page_defrag != null ? linux_os_config.value.transparent_huge_page_defrag : null
      transparent_huge_page_enabled = linux_os_config.value.transparent_huge_page_enabled != null ? linux_os_config.value.transparent_huge_page_enabled : null

      dynamic "sysctl_config" {
        for_each = var.linux_os_config.sysctl_config != null ? [var.linux_os_config.sysctl_config] : []

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
    for_each = var.node_network_profile != null ? [var.node_network_profile] : []

    content {
      application_security_group_ids = var.node_network_profile.application_security_group_ids
      node_public_ip_tags            = var.node_network_profile.node_public_ip_tags

      dynamic "allowed_host_ports" {
        for_each = var.node_network_profile.allowed_host_ports != null ? [var.node_network_profile.allowed_host_ports] : []

        content {
          port_end   = allowed_host_ports.value.port_end
          port_start = allowed_host_ports.value.port_start
          protocol   = allowed_host_ports.value.protocol
        }
      }
    }
  }
  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
  dynamic "upgrade_settings" {
    for_each = var.upgrade_settings != null ? [var.upgrade_settings] : []

    content {
      max_surge                     = upgrade_settings.value.max_surge
      drain_timeout_in_minutes      = upgrade_settings.value.drain_timeout_in_minutes
      node_soak_duration_in_minutes = upgrade_settings.value.node_soak_duration_in_minutes
    }
  }
  dynamic "windows_profile" {
    for_each = var.windows_profile != null ? [var.windows_profile] : []

    content {
      outbound_nat_enabled = windows_profile.value.outbound_nat_enabled
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      name
    ]
    replace_triggered_by = [
      terraform_data.pool_name_keeper,
    ]

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
}

resource "terraform_data" "pool_name_keeper" {
  triggers_replace = {
    pool_name = var.name
  }
}
