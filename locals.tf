locals {
  advanced_networking = var.advanced_networking != null ? {
    enabled = true
    observability = var.advanced_networking.observability != null ? {
      enabled = var.advanced_networking.observability.enabled
    } : null
    security = var.advanced_networking.security != null ? {
      enabled                 = var.advanced_networking.security.enabled
      advancedNetworkPolicies = var.advanced_networking.security.advanced_network_policies
      transit_encryption = var.advanced_networking.security.transit_encryption != null ? {
        type = var.advanced_networking.security.transit_encryption.type
      } : null
    } : null
    performance = var.advanced_networking.performance != null ? {
      accelerationMode = var.advanced_networking.performance.acceleration_mode
    } : null
  } : null
  agent_pool_profile_template = {
    availabilityZones = null
    count             = null
    enableAutoScaling = null
    maxCount          = null
    minCount          = null
    mode              = null
    name              = null
    osType            = null
    type              = null
    vmSize            = null
    vnetSubnetID      = null
  }
  agent_pool_profiles = local.agent_pool_profiles_raw == null ? null : [
    for profile in local.agent_pool_profiles_raw : {
      for k, v in merge(
        profile,
        profile.count == null ? {} : { count = tonumber(profile.count) }
      ) : k => v if !(can(v == null) && v == null)
    }
  ]
  agent_pool_profiles_automatic = local.is_automatic ? [
    merge(
      local.agent_pool_profile_template,
      {
        name         = local.default_node_pool_name
        mode         = "System"
        count        = local.default_node_pool_count != null ? local.default_node_pool_count : 3
        vnetSubnetID = var.default_node_pool.vnet_subnet_id
      }
    )
  ] : []
  agent_pool_profiles_combined = concat(local.agent_pool_profiles_automatic, local.agent_pool_profiles_standard)
  agent_pool_profiles_raw      = length(local.agent_pool_profiles_combined) == 0 ? null : local.agent_pool_profiles_combined
  agent_pool_profiles_standard = local.is_automatic ? [] : [
    merge(
      local.agent_pool_profile_template,
      {
        mode              = "System"
        osType            = "Linux"
        name              = local.default_node_pool_name
        count             = local.default_node_pool_count
        vmSize            = var.default_node_pool.vm_size
        enableAutoScaling = var.default_node_pool.auto_scaling_enabled
        minCount          = local.default_node_pool_min_count
        maxCount          = local.default_node_pool_max_count
        type              = var.default_node_pool.type
        vnetSubnetID      = var.default_node_pool.vnet_subnet_id
        availabilityZones = try(length(var.default_node_pool.zones) > 0 ? var.default_node_pool.zones : null, null)
      }
    )
  ]
  api_server_access_profile = var.api_server_access_profile != null ? {
    authorizedIPRanges             = var.api_server_access_profile.authorized_ip_ranges
    enablePrivateCluster           = var.api_server_access_profile.enable_private_cluster
    enablePrivateClusterPublicFQDN = var.api_server_access_profile.enable_private_cluster_public_fqdn
    privateDnsZone                 = var.api_server_access_profile.private_dns_zone_id
    subnetId                       = var.api_server_access_profile.subnet_id
    disableRunCommand              = !var.api_server_access_profile.run_command_enabled
  } : null
  auto_scaler_profile_map = (
    local.is_automatic || !var.default_node_pool.auto_scaling_enabled || var.auto_scaler_profile == null
    ) ? null : {
    balanceSimilarNodeGroups                 = var.auto_scaler_profile.balance_similar_node_groups
    daemonsetEvictionForEmptyNodesEnabled    = var.auto_scaler_profile.daemonset_eviction_for_empty_nodes_enabled
    daemonsetEvictionForOccupiedNodesEnabled = var.auto_scaler_profile.daemonset_eviction_for_occupied_nodes_enabled
    emptyBulkDeleteMax                       = var.auto_scaler_profile.empty_bulk_delete_max
    expander                                 = var.auto_scaler_profile.expander
    ignoreDaemonsetsUtilizationEnabled       = var.auto_scaler_profile.ignore_daemonsets_utilization_enabled
    maxGracefulTerminationSec                = var.auto_scaler_profile.max_graceful_termination_sec
    maxNodeProvisioningTime                  = var.auto_scaler_profile.max_node_provisioning_time
    maxUnreadyNodes                          = var.auto_scaler_profile.max_unready_nodes
    maxUnreadyPercentage                     = var.auto_scaler_profile.max_unready_percentage
    newPodScaleUpDelay                       = var.auto_scaler_profile.new_pod_scale_up_delay
    scaleDownDelayAfterAdd                   = var.auto_scaler_profile.scale_down_delay_after_add
    scaleDownDelayAfterDelete                = var.auto_scaler_profile.scale_down_delay_after_delete
    scaleDownDelayAfterFailure               = var.auto_scaler_profile.scale_down_delay_after_failure
    scaleDownUnneeded                        = var.auto_scaler_profile.scale_down_unneeded
    scaleDownUnready                         = var.auto_scaler_profile.scale_down_unready
    scaleDownUtilizationThreshold            = var.auto_scaler_profile.scale_down_utilization_threshold
    scanInterval                             = var.auto_scaler_profile.scan_interval
    skipNodesWithLocalStorage                = var.auto_scaler_profile.skip_nodes_with_local_storage
    skipNodesWithSystemPods                  = var.auto_scaler_profile.skip_nodes_with_system_pods
  }
  automatic_channel_upgrade_check = var.automatic_upgrade_channel == null ? true : (
    (contains(["patch"], var.automatic_upgrade_channel) && can(regex("^[0-9]{1,}\\.[0-9]{1,}$", var.kubernetes_version)) && (can(regex("^[0-9]{1,}\\.[0-9]{1,}$", var.default_node_pool.orchestrator_version)) || var.default_node_pool.orchestrator_version == null)) ||
    (contains(["rapid", "stable", "node-image"], var.automatic_upgrade_channel) && var.kubernetes_version == null && var.default_node_pool.orchestrator_version == null)
  )
  default_node_pool_count     = var.default_node_pool.node_count == null ? null : tonumber(var.default_node_pool.node_count)
  default_node_pool_max_count = var.default_node_pool.max_count == null ? null : tonumber(var.default_node_pool.max_count)
  default_node_pool_min_count = var.default_node_pool.min_count == null ? null : tonumber(var.default_node_pool.min_count)
  default_node_pool_name      = coalesce(try(var.default_node_pool.name, null), "systempool")
  ingress_profile = {
    webAppRouting = {
      nginx = {
        defaultIngressControllerType = var.default_nginx_controller
      }
      dnsZoneResourceIds = distinct(concat(flatten(values(var.web_app_routing_dns_zone_ids))))
      enabled            = true
    }
  }
  is_automatic = var.sku.name == "Automatic"
  managed_identities = {
    system_assigned_user_assigned = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
  monitor_profile = local.monitor_profile_enabled ? {
    metrics = local.monitor_profile_metrics
  } : null
  monitor_profile_enabled = var.prometheus_workspace_id != null || var.monitor_metrics != null
  monitor_profile_kube_state_metrics = var.monitor_metrics == null ? null : {
    metricAnnotationsAllowList = coalesce(var.monitor_metrics.annotations_allowed, "")
    metricLabelsAllowlist      = coalesce(var.monitor_metrics.labels_allowed, "")
  }
  monitor_profile_metrics = merge(
    {
      enabled = true
    },
    local.monitor_profile_kube_state_metrics != null ? {
      kubeStateMetrics = local.monitor_profile_kube_state_metrics
    } : {}
  )
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
  properties_base = {
    addonProfiles          = local.addon_profiles
    agentPoolProfiles      = local.agent_pool_profiles
    apiServerAccessProfile = local.api_server_access_profile
    azureMonitorProfile    = local.monitor_profile
    diskEncryptionSetID    = var.disk_encryption_set_id
    kubernetesVersion      = var.kubernetes_version
    networkProfile         = local.network_profile_map
    ingressProfile         = local.ingress_profile
    # Placeholders (null) for non-Automatic-only attributes so object type remains consistent across ternary
    autoScalerProfile  = null
    autoUpgradeProfile = null
    dnsPrefix          = null
    httpProxyConfig    = null
    oidcIssuerProfile  = null
    securityProfile    = null
    windowsProfile     = null
    storageProfile     = null
    supportPlan        = null
  }
  properties_final          = { for k, v in local.properties_final_preclean : k => v if v != null }
  properties_final_preclean = local.is_automatic ? local.properties_base : merge(local.properties_base, local.properties_standard_only)
  properties_standard_only = {
    httpProxyConfig = var.http_proxy_config != null ? {
      enabled    = true
      httpProxy  = var.http_proxy_config.http_proxy
      httpsProxy = var.http_proxy_config.https_proxy
      noProxy    = var.http_proxy_config.no_proxy
      trustedCa  = var.http_proxy_config.trusted_ca
    } : null
    dnsPrefix = coalesce(var.dns_prefix, var.dns_prefix_private_cluster, random_string.dns_prefix.result)
    autoUpgradeProfile = (var.automatic_upgrade_channel != null || var.node_os_channel_upgrade != null) ? {
      upgradeChannel       = var.automatic_upgrade_channel
      nodeOSUpgradeChannel = var.node_os_channel_upgrade
    } : null
    oidcIssuerProfile = var.oidc_issuer_enabled ? { enabled = true } : { enabled = false }
    securityProfile = (var.workload_identity_enabled || var.image_cleaner_enabled || var.defender_log_analytics_workspace_id != null) ? {
      workloadIdentity = var.workload_identity_enabled ? { enabled = true } : null
      imageCleaner = var.image_cleaner_enabled ? {
        enabled       = true,
        intervalHours = var.image_cleaner_interval_hours
      } : null
      defender = var.defender_log_analytics_workspace_id != null ? {
        logAnalyticsWorkspaceResourceId = var.defender_log_analytics_workspace_id
      } : null
      } : {
      workloadIdentity = null
      imageCleaner     = null
      defender         = null
    }
    autoScalerProfile = local.auto_scaler_profile_map
    windowsProfile = var.windows_profile != null ? {
      adminUsername  = var.windows_profile.admin_username
      enableCSIProxy = var.windows_profile.csi_proxy_enabled
      gmsaProfile = var.windows_profile.gmsa != null ? {
        rootDomain = var.windows_profile.gmsa.root_domain
        enabled    = true
        dnsServer  = var.windows_profile.gmsa.dns_server
      } : null
    } : null
    storageProfile = var.storage_profile != null ? {
      diskCSIDriver      = { enabled = var.storage_profile.disk_driver_enabled }
      fileCSIDriver      = { enabled = var.storage_profile.file_driver_enabled }
      blobCSIDriver      = { enabled = var.storage_profile.blob_driver_enabled }
      snapshotController = { enabled = var.storage_profile.snapshot_controller_enabled }
    } : null
    supportPlan = var.support_plan
  }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
