resource "azurerm_kubernetes_cluster" "this" {
  location            = var.location
  name                = "${var.name}${var.cluster_suffix}"
  resource_group_name = var.resource_group_name
  # Upgrade Configuration
  automatic_upgrade_channel = var.automatic_upgrade_channel
  # Additional Features
  azure_policy_enabled             = var.azure_policy_enabled
  cost_analysis_enabled            = var.sku_tier == "Free" ? false : var.cost_analysis_enabled
  disk_encryption_set_id           = var.disk_encryption_set_id
  dns_prefix                       = var.private_cluster_enabled ? null : local.dns_prefix
  dns_prefix_private_cluster       = var.private_cluster_enabled ? local.private_dns_prefix : null
  http_application_routing_enabled = var.http_application_routing_enabled
  image_cleaner_enabled            = var.image_cleaner_enabled
  kubernetes_version               = var.kubernetes_version
  # Access Control Configuration
  local_account_disabled  = var.local_account_disabled
  node_os_upgrade_channel = var.node_os_channel_upgrade
  node_resource_group     = var.node_resource_group_name != "" ? var.node_resource_group_name : null
  oidc_issuer_enabled     = var.oidc_issuer_enabled
  # Service Mesh Configuration
  open_service_mesh_enabled = var.open_service_mesh_enabled
  # Private Cluster Configuration
  private_cluster_enabled             = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = var.private_cluster_enabled ? var.private_cluster_public_fqdn_enabled : null
  private_dns_zone_id                 = var.private_cluster_enabled ? var.private_dns_zone_id : null
  role_based_access_control_enabled   = var.role_based_access_control_enabled
  run_command_enabled                 = var.run_command_enabled
  sku_tier                            = var.sku_tier
  support_plan                        = var.support_plan
  tags                                = var.tags
  workload_identity_enabled           = var.workload_identity_enabled

  # Default Nodepool Configuration
  dynamic "default_node_pool" {
    for_each = var.default_node_pool != null ? [var.default_node_pool] : []

    content {
      name                          = default_node_pool.value.name
      vm_size                       = default_node_pool.value.vm_size
      auto_scaling_enabled          = default_node_pool.value.auto_scaling_enabled
      capacity_reservation_group_id = default_node_pool.value.capacity_reservation_group_id
      fips_enabled                  = default_node_pool.value.fips_enabled
      gpu_instance                  = default_node_pool.value.gpu_instance
      host_encryption_enabled       = default_node_pool.value.host_encryption_enabled
      host_group_id                 = default_node_pool.value.host_group_id
      kubelet_disk_type             = default_node_pool.value.kubelet_disk_type
      max_count                     = default_node_pool.value.max_count
      max_pods                      = default_node_pool.value.max_pods
      min_count                     = default_node_pool.value.min_count
      node_count                    = default_node_pool.value.node_count
      node_labels                   = default_node_pool.value.node_labels
      node_public_ip_enabled        = default_node_pool.value.node_public_ip_enabled
      node_public_ip_prefix_id      = default_node_pool.value.node_public_ip_prefix_id
      only_critical_addons_enabled  = default_node_pool.value.only_critical_addons_enabled
      orchestrator_version          = default_node_pool.value.orchestrator_version
      os_disk_size_gb               = default_node_pool.value.os_disk_size_gb
      os_disk_type                  = default_node_pool.value.os_disk_type
      os_sku                        = default_node_pool.value.os_sku
      pod_subnet_id                 = default_node_pool.value.pod_subnet_id
      proximity_placement_group_id  = default_node_pool.value.proximity_placement_group_id
      scale_down_mode               = default_node_pool.value.scale_down_mode
      snapshot_id                   = default_node_pool.value.snapshot_id
      tags                          = default_node_pool.value.tags
      temporary_name_for_rotation   = default_node_pool.value.temporary_name_for_rotation
      type                          = default_node_pool.value.type
      ultra_ssd_enabled             = default_node_pool.value.ultra_ssd_enabled
      vnet_subnet_id                = default_node_pool.value.vnet_subnet_id
      workload_runtime              = default_node_pool.value.workload_runtime
      zones                         = default_node_pool.value.zones

      dynamic "kubelet_config" {
        for_each = var.default_node_pool.kubelet_config != null ? [var.default_node_pool.kubelet_config] : []

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
        for_each = var.default_node_pool.linux_os_config != null ? [var.default_node_pool.linux_os_config] : []

        content {
          swap_file_size_mb             = linux_os_config.value.swap_file_size_mb
          transparent_huge_page_defrag  = linux_os_config.value.transparent_huge_page_defrag
          transparent_huge_page_enabled = linux_os_config.value.transparent_huge_page_enabled

          dynamic "sysctl_config" {
            for_each = var.default_node_pool.linux_os_config.sysctl_config != null ? [var.default_node_pool.linux_os_config.sysctl_config] : []

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
      dynamic "upgrade_settings" {
        for_each = default_node_pool.value.upgrade_settings != null ? [default_node_pool.value.upgrade_settings] : []

        content {
          max_surge                     = upgrade_settings.value.max_surge
          drain_timeout_in_minutes      = upgrade_settings.value.node_soak_duration_in_minutes
          node_soak_duration_in_minutes = upgrade_settings.value.node_soak_duration_in_minutes
        }
      }
    }
  }
  dynamic "aci_connector_linux" {
    for_each = var.aci_connector_linux_subnet_name != null ? [var.aci_connector_linux_subnet_name] : []

    content {
      subnet_name = aci_connector_linux.value
    }
  }
  dynamic "api_server_access_profile" {
    for_each = var.api_server_access_profile != null ? [var.api_server_access_profile] : []

    content {
      authorized_ip_ranges = api_server_access_profile.value.authorized_ip_ranges
    }
  }
  # Auto Scaler Configuration
  dynamic "auto_scaler_profile" {
    for_each = var.auto_scaler_profile != null ? [var.auto_scaler_profile] : []

    content {
      balance_similar_node_groups      = auto_scaler_profile.value.balance_similar_node_groups
      empty_bulk_delete_max            = auto_scaler_profile.value.empty_bulk_delete_max
      expander                         = auto_scaler_profile.value.expander
      max_graceful_termination_sec     = auto_scaler_profile.value.max_graceful_termination_sec
      max_node_provisioning_time       = auto_scaler_profile.value.max_node_provisioning_time
      max_unready_nodes                = auto_scaler_profile.value.max_unready_nodes
      max_unready_percentage           = auto_scaler_profile.value.max_unready_percentage
      new_pod_scale_up_delay           = auto_scaler_profile.value.new_pod_scale_up_delay
      scale_down_delay_after_add       = auto_scaler_profile.value.scale_down_delay_after_add
      scale_down_delay_after_delete    = auto_scaler_profile.value.scale_down_delay_after_delete
      scale_down_delay_after_failure   = auto_scaler_profile.value.scale_down_delay_after_failure
      scale_down_unneeded              = auto_scaler_profile.value.scale_down_unneeded
      scale_down_unready               = auto_scaler_profile.value.scale_down_unready
      scale_down_utilization_threshold = auto_scaler_profile.value.scale_down_utilization_threshold
      skip_nodes_with_local_storage    = auto_scaler_profile.value.skip_nodes_with_local_storage
      skip_nodes_with_system_pods      = auto_scaler_profile.value.skip_nodes_with_system_pods
    }
  }
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.azure_active_directory_role_based_access_control != null ? [var.azure_active_directory_role_based_access_control] : []

    content {
      admin_group_object_ids = azure_active_directory_role_based_access_control.value.admin_group_object_ids
      azure_rbac_enabled     = azure_active_directory_role_based_access_control.value.azure_rbac_enabled
      tenant_id              = azure_active_directory_role_based_access_control.value.tenant_id
    }
  }
  # Proxy, Ingress and Routing Configuration
  dynamic "http_proxy_config" {
    for_each = var.http_proxy_config != null ? [var.http_proxy_config] : []

    content {
      http_proxy  = http_proxy_config.value.http_proxy
      https_proxy = http_proxy_config.value.https_proxy
      no_proxy    = http_proxy_config.value.no_proxy
      trusted_ca  = http_proxy_config.value.trusted_ca
    }
  }
  # Identity Configuration
  identity {
    type         = var.identity.type
    identity_ids = var.identity.identity_ids != null ? var.identity.identity_ids : []
  }
  # Ingress Configuration
  dynamic "ingress_application_gateway" {
    for_each = var.ingress_application_gateway != null ? [var.ingress_application_gateway] : []

    content {
      gateway_id   = ingress_application_gateway.value.gateway_id
      gateway_name = ingress_application_gateway.value.gateway_name
      subnet_cidr  = ingress_application_gateway.value.subnet_cidr
      subnet_id    = ingress_application_gateway.value.subnet_id
    }
  }
  # KeyVault Configuration
  dynamic "key_management_service" {
    for_each = var.key_management_service != null ? [var.key_management_service] : []

    content {
      key_vault_key_id         = key_management_service.value.key_vault_key_id
      key_vault_network_access = key_management_service.value.key_vault_network_access
    }
  }
  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider != null ? [var.key_vault_secrets_provider] : []

    content {
      secret_rotation_enabled  = key_vault_secrets_provider.value.secret_rotation_enabled
      secret_rotation_interval = key_vault_secrets_provider.value.secret_rotation_interval
    }
  }
  dynamic "kubelet_identity" {
    for_each = var.kubelet_identity != null ? [var.kubelet_identity] : []

    content {
      client_id                 = kubelet_identity.value.client_id
      object_id                 = kubelet_identity.value.object_id
      user_assigned_identity_id = kubelet_identity.value.user_assigned_identity_id
    }
  }
  # OS Configuration 
  dynamic "linux_profile" {
    for_each = var.linux_profile != null ? [var.linux_profile] : []

    content {
      admin_username = linux_profile.value.admin_username

      ssh_key {
        key_data = linux_profile.value.ssh_key
      }
    }
  }
  # Maintenance Configurations
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []

    content {
      dynamic "allowed" {
        for_each = maintenance_window.value.allowed != null ? [maintenance_window.value.allowed] : []

        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }
      dynamic "not_allowed" {
        for_each = maintenance_window.value.not_allowed != null ? [maintenance_window.value.not_allowed] : []

        content {
          end   = not_allowed.value.end
          start = not_allowed.value.start
        }
      }
    }
  }
  dynamic "maintenance_window_auto_upgrade" {
    for_each = var.maintenance_window_auto_upgrade != null ? [var.maintenance_window_auto_upgrade] : []

    content {
      duration     = maintenance_window_auto_upgrade.value.duration
      frequency    = maintenance_window_auto_upgrade.value.frequency
      interval     = maintenance_window_auto_upgrade.value.interval
      day_of_month = maintenance_window_auto_upgrade.value.day_of_month
      day_of_week  = maintenance_window_auto_upgrade.value.day_of_week
      start_date   = maintenance_window_auto_upgrade.value.start_date
      start_time   = maintenance_window_auto_upgrade.value.start_time
      utc_offset   = maintenance_window_auto_upgrade.value.utc_offset
      week_index   = maintenance_window_auto_upgrade.value.week_index

      dynamic "not_allowed" {
        for_each = maintenance_window_auto_upgrade.value.not_allowed != null ? [maintenance_window_auto_upgrade.value.not_allowed] : []

        content {
          end   = not_allowed.value.end
          start = not_allowed.value.start
        }
      }
    }
  }
  dynamic "maintenance_window_node_os" {
    for_each = var.maintenance_window_node_os != null ? [var.maintenance_window_node_os] : []

    content {
      duration     = maintenance_window_node_os.value.duration
      frequency    = maintenance_window_node_os.value.frequency
      interval     = maintenance_window_node_os.value.interval
      day_of_month = maintenance_window_node_os.value.day_of_month
      day_of_week  = maintenance_window_node_os.value.day_of_week
      start_date   = maintenance_window_node_os.value.start_date
      start_time   = maintenance_window_node_os.value.start_time
      utc_offset   = maintenance_window_node_os.value.utc_offset
      week_index   = maintenance_window_node_os.value.week_index

      dynamic "not_allowed" {
        for_each = maintenance_window_node_os.value.not_allowed != null ? [maintenance_window_node_os.value.not_allowed] : []

        content {
          end   = not_allowed.value.end
          start = not_allowed.value.start
        }
      }
    }
  }
  # Monitoring Configuration
  dynamic "microsoft_defender" {
    for_each = var.defender_log_analytics_workspace_id != null ? [var.defender_log_analytics_workspace_id] : []

    content {
      log_analytics_workspace_id = var.defender_log_analytics_workspace_id
    }
  }
  dynamic "monitor_metrics" {
    for_each = var.monitor_metrics != null ? [var.monitor_metrics] : []

    content {
      annotations_allowed = monitor_metrics.value.annotations_allowed
      labels_allowed      = monitor_metrics.value.labels_allowed
    }
  }
  #Network Configuration
  network_profile {
    network_plugin      = var.network_profile.network_plugin
    dns_service_ip      = var.network_profile.dns_service_ip
    ip_versions         = var.network_profile.ip_versions
    load_balancer_sku   = var.network_profile.load_balancer_sku
    network_data_plane  = var.network_profile.network_data_plane
    network_mode        = var.network_profile.network_mode
    network_plugin_mode = var.network_profile.network_plugin_mode
    network_policy      = var.network_profile.network_policy
    outbound_type       = var.network_profile.outbound_type
    pod_cidr            = var.network_profile.pod_cidr
    pod_cidrs           = var.network_profile.pod_cidrs
    service_cidr        = var.network_profile.service_cidr
    service_cidrs       = var.network_profile.service_cidrs

    dynamic "load_balancer_profile" {
      for_each = var.network_profile.load_balancer_profile != null ? [var.network_profile.load_balancer_profile] : []

      content {
        idle_timeout_in_minutes     = var.network_profile.load_balancer_profile.idle_timeout_in_minutes
        managed_outbound_ip_count   = var.network_profile.load_balancer_profile.managed_outbound_ip_count
        managed_outbound_ipv6_count = var.network_profile.load_balancer_profile.managed_outbound_ipv6_count
        outbound_ip_address_ids     = var.network_profile.load_balancer_profile.outbound_ip_address_ids
        outbound_ip_prefix_ids      = var.network_profile.load_balancer_profile.outbound_ip_prefix_ids
        outbound_ports_allocated    = var.network_profile.load_balancer_profile.outbound_ports_allocated
      }
    }
    dynamic "nat_gateway_profile" {
      for_each = var.network_profile.nat_gateway_profile != null ? [var.network_profile.nat_gateway_profile] : []

      content {
        idle_timeout_in_minutes   = var.network_profile.nat_gateway_profile.idle_timeout_in_minutes
        managed_outbound_ip_count = var.network_profile.nat_gateway_profile.managed_outbound_ip_count
      }
    }
  }
  dynamic "oms_agent" {
    for_each = var.oms_agent != null ? [var.oms_agent] : []

    content {
      log_analytics_workspace_id      = oms_agent.value.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = oms_agent.value.msi_auth_for_monitoring_enabled
    }
  }
  dynamic "service_mesh_profile" {
    for_each = var.service_mesh_profile != null ? [var.service_mesh_profile] : []

    content {
      mode                             = service_mesh_profile.value.mode
      revisions                        = service_mesh_profile.value.revisions
      external_ingress_gateway_enabled = service_mesh_profile.value.external_ingress_gateway_enabled
      internal_ingress_gateway_enabled = service_mesh_profile.value.internal_ingress_gateway_enabled

      dynamic "certificate_authority" {
        for_each = service_mesh_profile.value.certificate_authority != null ? [service_mesh_profile.value.certificate_authority] : []

        content {
          cert_chain_object_name = certificate_authority.value.cert_chain_object_name
          cert_object_name       = certificate_authority.value.cert_object_name
          key_object_name        = certificate_authority.value.key_object_name
          key_vault_id           = certificate_authority.value.key_vault_id
          root_cert_object_name  = certificate_authority.value.root_cert_object_name
        }
      }
    }
  }
  dynamic "service_principal" {
    for_each = var.service_principal != null ? [var.service_principal] : []

    content {
      client_id     = service_principal.value.client_id
      client_secret = service_principal.value.client_secret
    }
  }
  # Storage Profile Configuration
  dynamic "storage_profile" {
    for_each = var.storage_profile != null ? [var.storage_profile] : []

    content {
      blob_driver_enabled         = storage_profile.value.blob_driver_enabled
      disk_driver_enabled         = storage_profile.value.disk_driver_enabled
      file_driver_enabled         = storage_profile.value.file_driver_enabled
      snapshot_controller_enabled = storage_profile.value.snapshot_controller_enabled
    }
  }
  dynamic "web_app_routing" {
    for_each = var.web_app_routing_dns_zone_ids

    content {
      dns_zone_ids = web_app_routing.value
    }
  }
  dynamic "windows_profile" {
    for_each = var.windows_profile != null ? [var.windows_profile] : []

    content {
      admin_password = windows_profile.value.admin_password
      admin_username = windows_profile.value.admin_username
      license        = windows_profile.value.license

      dynamic "gmsa" {
        for_each = var.windows_profile.gmsa != null ? [var.windows_profile.gmsa] : []

        content {
          dns_server  = var.windows_profile.gmsa.dns_server
          root_domain = var.windows_profile.gmsa.root_domain
        }
      }
    }
  }
  dynamic "workload_autoscaler_profile" {
    for_each = var.workload_autoscaler_profile != null ? [var.workload_autoscaler_profile] : []

    content {
      keda_enabled                    = workload_autoscaler_profile.value.keda_enabled
      vertical_pod_autoscaler_enabled = workload_autoscaler_profile.value.vpa_enabled
    }
  }

  lifecycle {
    ignore_changes = [
      http_application_routing_enabled,
      http_proxy_config[0].no_proxy,
      kubernetes_version
    ]

    precondition {
      # Why don't use var.identity_ids != null && length(var.identity_ids)>0 ? Because bool expression in Terraform is not short circuit so even var.identity_ids is null Terraform will still invoke length function with null and cause error. https://github.com/hashicorp/terraform/issues/24128
      condition     = (var.identity.type == "SystemAssigned") || (var.identity.identity_ids == null ? false : length(var.identity.identity_ids) > 0)
      error_message = "If use identity and `UserAssigned` is set, an `identity_ids` must be set as well."
    }
    precondition {
      condition     = var.cost_analysis_enabled != true || (var.sku_tier == "Standard" || var.sku_tier == "Premium")
      error_message = "`sku_tier` must be either `Standard` or `Premium` when cost analysis is enabled."
    }
    precondition {
      condition     = !((var.network_profile.load_balancer_profile != null) && var.network_profile.load_balancer_sku != "standard")
      error_message = "Enabling load_balancer_profile requires that `load_balancer_sku` be set to `standard`"
    }
    precondition {
      condition     = local.automatic_channel_upgrade_check
      error_message = "Either disable automatic upgrades, or specify `kubernetes_version` or `orchestrator_version` only up to the minor version when using `automatic_channel_upgrade=patch`. You don't need to specify `kubernetes_version` at all when using `automatic_channel_upgrade=stable|rapid|node-image`, where `orchestrator_version` always must be set to `null`."
    }
    precondition {
      condition     = var.role_based_access_control_enabled || !(var.azure_active_directory_role_based_access_control != null)
      error_message = "Enabling Azure Active Directory integration requires that `role_based_access_control_enabled` be set to true."
    }
    precondition {
      condition     = !((var.key_management_service != null) && var.identity.type != "UserAssigned")
      error_message = "KMS etcd encryption doesn't work with system-assigned managed identity."
    }
    precondition {
      condition     = !var.workload_identity_enabled || var.oidc_issuer_enabled
      error_message = "`oidc_issuer_enabled` must be set to `true` to enable Azure AD Workload Identity"
    }
    precondition {
      condition     = var.network_profile.network_mode != "overlay" || var.network_profile.network_plugin == "azure"
      error_message = "When network_plugin_mode is set to `overlay`, the network_plugin field can only be set to azure."
    }
    precondition {
      condition     = var.network_profile.network_policy != "cilium" || var.network_profile.network_plugin == "azure"
      error_message = "When the network policy is set to cilium, the network_plugin field can only be set to azure."
    }
    precondition {
      condition     = var.network_profile.network_policy != "cilium" || var.network_profile.network_plugin_mode == "overlay" || var.default_node_pool.pod_subnet_id != null
      error_message = "When the network policy is set to cilium, one of either network_plugin_mode = `overlay` or pod_subnet_id must be specified."
    }
    precondition {
      condition     = can(coalesce(var.name, var.dns_prefix))
      error_message = "You must set one of `var.cluster_name` and `var.prefix` to create `azurerm_kubernetes_cluster.main`."
    }
    precondition {
      condition     = !var.private_cluster_enabled || (var.dns_prefix_private_cluster != null && var.dns_prefix_private_cluster != "")
      error_message = "When `private_cluster_enabled` is set to `true`, `dns_prefix_private_cluster` must be set."
    }
    precondition {
      condition     = !var.private_cluster_enabled || (var.dns_prefix == null || var.dns_prefix == "")
      error_message = "When `dns_prefix_private_cluster` is set, `dns_prefix` must not be set."
    }
    precondition {
      condition     = var.automatic_upgrade_channel != "node-image" || var.node_os_channel_upgrade == "NodeImage"
      error_message = "`node_os_channel_upgrade` must be set to `NodeImage` if `automatic_channel_upgrade` has been set to `node-image`."
    }
    precondition {
      condition = (var.kubelet_identity == null) || (
      var.identity.type == "UserAssigned" && try(length(var.identity.identity_ids), 0) > 0)
      error_message = "When `kubelet_identity` is enabled - The `type` field in the `identity` block must be set to `UserAssigned` and `identity_ids` must be set."
    }
    precondition {
      condition     = !var.default_node_pool.auto_scaling_enabled || var.default_node_pool.type == "VirtualMachineScaleSets"
      error_message = "Autoscaling on default node pools is only supported when the Kubernetes Cluster is using Virtual Machine Scale Sets type nodes."
    }
    precondition {
      condition     = var.node_pools == null || var.default_node_pool.type == "VirtualMachineScaleSets"
      error_message = "The 'type' variable must be set to 'VirtualMachineScaleSets' if 'node_pools' is not null."
    }
  }
}

resource "null_resource" "kubernetes_version_keeper" {
  triggers = {
    version = var.kubernetes_version
  }
}

resource "azapi_update_resource" "aks_cluster_post_create" {
  type = "Microsoft.ContainerService/managedClusters@2024-02-01"
  body = {
    properties = {
      kubernetesVersion = var.kubernetes_version
    }
  }
  resource_id = azurerm_kubernetes_cluster.this.id

  lifecycle {
    ignore_changes       = all
    replace_triggered_by = [null_resource.kubernetes_version_keeper.id]
  }
}

resource "null_resource" "http_proxy_config_no_proxy_keeper" {
  count = can(var.http_proxy_config.no_proxy[0]) ? 1 : 0

  triggers = {
    http_proxy_no_proxy = try(join(",", try(sort(var.http_proxy_config.no_proxy), [])), "")
  }
}

resource "azapi_update_resource" "aks_cluster_http_proxy_config_no_proxy" {
  count = can(var.http_proxy_config.no_proxy[0]) ? 1 : 0

  type = "Microsoft.ContainerService/managedClusters@2024-02-01"
  body = {
    properties = {
      httpProxyConfig = {
        noProxy = var.http_proxy_config.no_proxy
      }
    }
  }
  resource_id = azurerm_kubernetes_cluster.this.id

  depends_on = [azapi_update_resource.aks_cluster_post_create]

  lifecycle {
    ignore_changes       = all
    replace_triggered_by = [null_resource.http_proxy_config_no_proxy_keeper[0].id]
  }
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_kubernetes_cluster.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_kubernetes_cluster.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "random_string" "dns_prefix" {
  length  = 10    # Set the length of the string
  lower   = true  # Use lowercase letters
  numeric = true  # Include numbers
  special = false # No special characters
  upper   = false # No uppercase letters
}
