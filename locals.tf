locals {
  addon_profiles = merge(
    local.log_analytics_workspace_id != null ? {
      omsagent = {
        enabled = true
        config = {
          logAnalyticsWorkspaceResourceID = local.log_analytics_workspace_id
          useAADAuth                      = local.log_analytics_use_aad_auth ? "true" : "false"
        }
      }
    } : {},
    !local.is_automatic && var.azure_policy_enabled ? {
      azurepolicy = { enabled = true }
    } : {}
  )
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
  api_server_access_profile = (var.api_server_access_profile != null || var.private_cluster_enabled) ? {
    authorizedIPRanges   = try(var.api_server_access_profile.authorized_ip_ranges, null)
    enablePrivateCluster = var.private_cluster_enabled
    privateDnsZone       = var.private_cluster_enabled ? var.private_dns_zone_id : null
    subnetId             = try(var.api_server_access_profile.vnet_subnet_id, null)
  } : null
  auto_scaler_profile_map = (
    local.is_automatic || !try(var.default_node_pool.auto_scaling_enabled, false) || var.auto_scaler_profile == null
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
  is_automatic                = var.sku.name == "Automatic"
  log_analytics_use_aad_auth  = var.log_analytics_workspace_id != null && trimspace(var.log_analytics_workspace_id) != "" ? true : try(var.oms_agent.msi_auth_for_monitoring_enabled, false)
  log_analytics_workspace_id = (
    var.log_analytics_workspace_id != null && trimspace(var.log_analytics_workspace_id) != ""
    ? var.log_analytics_workspace_id
    : var.oms_agent != null && var.oms_agent.log_analytics_workspace_id != null && trimspace(var.oms_agent.log_analytics_workspace_id) != ""
    ? var.oms_agent.log_analytics_workspace_id
    : null
  )
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
  monitor_profile_enabled = local.monitor_workspace_id != null || var.monitor_metrics != null
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
  monitor_workspace_id = var.monitor_workspace_id != null && trimspace(var.monitor_workspace_id) != "" ? var.monitor_workspace_id : null
  network_profile_advanced = var.advanced_networking.enabled ? {
    enabled       = true
    observability = var.advanced_networking.observability_enabled ? { enabled = true } : null
    security      = var.advanced_networking.security_enabled ? { enabled = true } : null
  } : null
  network_profile_combined = local.is_automatic ? merge(
    local.network_profile_template,
    {
      outboundType = var.network_profile.outbound_type
    }
    ) : merge(
    local.network_profile_template,
    {
      networkPlugin       = var.network_profile.network_plugin
      dnsServiceIP        = var.network_profile.dns_service_ip
      networkPolicy       = var.network_profile.network_policy
      outboundType        = var.network_profile.outbound_type
      podCidr             = var.network_profile.pod_cidr
      podCidrs            = var.network_profile.pod_cidrs
      serviceCidr         = var.network_profile.service_cidr
      serviceCidrs        = var.network_profile.service_cidrs
      advancedNetworking  = local.network_profile_advanced
      networkMode         = var.network_profile.network_mode
      networkPluginMode   = var.network_profile.network_plugin_mode
      networkDataplane    = var.network_profile.network_data_plane
      ipFamilies          = var.network_profile.ip_versions
      loadBalancerSku     = var.network_profile.load_balancer_sku
      loadBalancerProfile = local.network_profile_load_balancer_profile
      natGatewayProfile   = local.network_profile_nat_gateway_profile
    }
  )
  network_profile_filtered = { for k, v in local.network_profile_combined : k => v if v != null }
  network_profile_load_balancer_profile = var.network_profile.load_balancer_profile == null ? null : {
    managedOutboundIPs = (
      var.network_profile.load_balancer_profile.managed_outbound_ip_count == null &&
      var.network_profile.load_balancer_profile.managed_outbound_ipv6_count == null
      ) ? null : {
      count     = var.network_profile.load_balancer_profile.managed_outbound_ip_count
      countIPv6 = var.network_profile.load_balancer_profile.managed_outbound_ipv6_count
    }
    outboundIPs = length(try(var.network_profile.load_balancer_profile.outbound_ip_address_ids, [])) == 0 ? null : {
      publicIPs = [for id in var.network_profile.load_balancer_profile.outbound_ip_address_ids : { id = id }]
    }
    outboundIPPrefixes = length(try(var.network_profile.load_balancer_profile.outbound_ip_prefix_ids, [])) == 0 ? null : {
      publicIPPrefixes = [for id in var.network_profile.load_balancer_profile.outbound_ip_prefix_ids : { id = id }]
    }
    allocatedOutboundPorts = try(var.network_profile.load_balancer_profile.outbound_ports_allocated, null)
    idleTimeoutInMinutes   = try(var.network_profile.load_balancer_profile.idle_timeout_in_minutes, null)
  }
  network_profile_map = local.is_automatic ? (
    var.network_profile.outbound_type != null && var.network_profile.outbound_type != "loadBalancer" ? local.network_profile_filtered : null
  ) : local.network_profile_filtered
  network_profile_nat_gateway_profile = var.network_profile.nat_gateway_profile == null ? null : {
    managedOutboundIPProfile = (
      try(var.network_profile.nat_gateway_profile.managed_outbound_ip_count, null) == null
      ) ? null : {
      count = var.network_profile.nat_gateway_profile.managed_outbound_ip_count
    }
    idleTimeoutInMinutes = try(var.network_profile.nat_gateway_profile.idle_timeout_in_minutes, null)
  }
  network_profile_template = {
    networkPlugin       = null
    dnsServiceIP        = null
    networkPolicy       = null
    outboundType        = null
    podCidr             = null
    podCidrs            = null
    serviceCidr         = null
    serviceCidrs        = null
    advancedNetworking  = null
    networkMode         = null
    networkPluginMode   = null
    networkDataplane    = null
    ipFamilies          = null
    loadBalancerSku     = null
    loadBalancerProfile = null
    natGatewayProfile   = null
  }
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
    kubernetesVersion      = var.kubernetes_version
    addonProfiles          = local.addon_profiles
    azureMonitorProfile    = local.monitor_profile
    agentPoolProfiles      = local.agent_pool_profiles
    apiServerAccessProfile = local.api_server_access_profile
    networkProfile         = local.network_profile_map
    # Placeholders (null) for non-Automatic-only attributes so object type remains consistent across ternary
    dnsPrefix          = null
    autoUpgradeProfile = null
    oidcIssuerProfile  = null
    securityProfile    = null
    autoScalerProfile  = null
  }
  properties_final          = { for k, v in local.properties_final_preclean : k => v if v != null }
  properties_final_preclean = local.is_automatic ? local.properties_base : merge(local.properties_base, local.properties_standard_only)
  properties_standard_only = {
    dnsPrefix = coalesce(var.dns_prefix, var.dns_prefix_private_cluster, random_string.dns_prefix.result)
    autoUpgradeProfile = (var.automatic_upgrade_channel != null || var.node_os_channel_upgrade != null) ? {
      upgradeChannel       = var.automatic_upgrade_channel
      nodeOSUpgradeChannel = var.node_os_channel_upgrade
    } : null
    oidcIssuerProfile = var.oidc_issuer_enabled ? { enabled = true } : { enabled = false }
    securityProfile = (var.workload_identity_enabled || var.image_cleaner_enabled || var.defender_log_analytics_workspace_id != null) ? {
      workloadIdentity = var.workload_identity_enabled ? { enabled = true } : null
      imageCleaner     = var.image_cleaner_enabled ? { enabled = true, intervalHours = var.image_cleaner_interval_hours } : null
      defender         = var.defender_log_analytics_workspace_id != null ? { logAnalyticsWorkspaceResourceId = var.defender_log_analytics_workspace_id } : null
      } : {
      workloadIdentity = null
      imageCleaner     = null
      defender         = null
    }
    autoScalerProfile = local.auto_scaler_profile_map
  }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
