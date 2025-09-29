data "azurerm_client_config" "current" {}

# Locals for network profile (moved out of resource body to simplify expressions)
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
    availabilityZones       = null
    count                   = null
    enableAutoScaling       = null
    enableClusterAutoscaler = null
    maxCount                = null
    minCount                = null
    mode                    = null
    name                    = null
    osType                  = null
    type                    = null
    vmSize                  = null
    vnetSubnetID            = null
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
        name  = local.default_node_pool_name
        mode  = "System"
        count = local.default_node_pool_count != null ? local.default_node_pool_count : 3
      }
    )
  ] : []
  agent_pool_profiles_combined = concat(local.agent_pool_profiles_automatic, local.agent_pool_profiles_standard)
  agent_pool_profiles_raw      = length(local.agent_pool_profiles_combined) == 0 ? null : local.agent_pool_profiles_combined
  agent_pool_profiles_standard = local.is_automatic ? [] : [
    merge(
      local.agent_pool_profile_template,
      {
        mode                    = "System"
        osType                  = "Linux"
        name                    = local.default_node_pool_name
        count                   = local.default_node_pool_count
        vmSize                  = var.default_node_pool.vm_size
        enableAutoScaling       = var.default_node_pool.auto_scaling_enabled
        enableClusterAutoscaler = var.default_node_pool.auto_scaling_enabled
        minCount                = local.default_node_pool_min_count
        maxCount                = local.default_node_pool_max_count
        type                    = var.default_node_pool.type
        vnetSubnetID            = var.default_node_pool.vnet_subnet_id
        availabilityZones       = try(length(var.default_node_pool.zones) > 0 ? var.default_node_pool.zones : null, null)
      }
    )
  ]
  # Optional cluster autoscaler profile mapping (only for non-Automatic SKU when autoscaling explicitly enabled)
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
  network_profile_map = { for k, v in local.network_profile_map_raw : k => v if v != null }
  network_profile_map_raw = {
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
  network_profile_nat_gateway_profile = var.network_profile.nat_gateway_profile == null ? null : {
    managedOutboundIPProfile = (
      try(var.network_profile.nat_gateway_profile.managed_outbound_ip_count, null) == null
      ) ? null : {
      count = var.network_profile.nat_gateway_profile.managed_outbound_ip_count
    }
    idleTimeoutInMinutes = try(var.network_profile.nat_gateway_profile.idle_timeout_in_minutes, null)
  }
  # Base properties always sent (both Automatic and non-Automatic)
  properties_base = {
    kubernetesVersion   = var.kubernetes_version
    addonProfiles       = local.addon_profiles
    azureMonitorProfile = local.monitor_profile
    agentPoolProfiles   = local.agent_pool_profiles
    # Placeholders (null) for non-Automatic-only attributes so object type remains consistent across ternary
    dnsPrefix              = null
    apiServerAccessProfile = null
    autoUpgradeProfile     = null
    oidcIssuerProfile      = null
    securityProfile        = null
    networkProfile         = null
    autoScalerProfile      = null
  }
  # Remove any top-level properties that resolved to null (we intentionally keep nested nulls where required)
  properties_final          = { for k, v in local.properties_final_preclean : k => v if v != null }
  properties_final_preclean = local.is_automatic ? local.properties_base : merge(local.properties_base, local.properties_standard_only)
  # Properties only for non-Automatic SKU. For Automatic we omit them entirely so Terraform does not try
  # to null them while the platform manages their values.
  properties_standard_only = {
    dnsPrefix = coalesce(var.dns_prefix, var.dns_prefix_private_cluster, random_string.dns_prefix.result)
    apiServerAccessProfile = (var.api_server_access_profile != null || var.private_cluster_enabled) ? {
      authorizedIPRanges   = try(var.api_server_access_profile.authorized_ip_ranges, null)
      enablePrivateCluster = var.private_cluster_enabled
      privateDnsZone       = var.private_cluster_enabled ? var.private_dns_zone_id : null
    } : null
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
    networkProfile    = local.network_profile_map
    autoScalerProfile = local.auto_scaler_profile_map
  }
}

resource "azapi_resource" "this" {
  location  = var.location
  name      = "${var.name}${var.cluster_suffix}"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.ContainerService/managedClusters@2025-07-01"
  body = {
    properties = local.properties_final
    sku        = var.sku
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = [
    "properties.oidcIssuerProfile.issuerURL",
    "properties.identityProfile",
    "properties.nodeResourceGroup"
  ]
  schema_validation_enabled = false
  tags                      = var.tags
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  identity {
    type         = local.is_automatic ? "SystemAssigned" : try(local.managed_identities.system_assigned_user_assigned.this.type, "SystemAssigned")
    identity_ids = local.is_automatic ? null : try(length(local.managed_identities.system_assigned_user_assigned.this.user_assigned_resource_ids) > 0 ? local.managed_identities.system_assigned_user_assigned.this.user_assigned_resource_ids : null, null)
  }

  lifecycle {
    ignore_changes = [
      body.properties.kubernetesVersion
    ]

    precondition {
      condition     = local.is_automatic || var.cost_analysis_enabled != true || (var.sku_tier == "Standard" || var.sku_tier == "Premium")
      error_message = "`sku_tier` must be either `Standard` or `Premium` when cost analysis is enabled."
    }
    precondition {
      condition     = !var.onboard_monitoring || (local.monitor_workspace_id != null && local.log_analytics_workspace_id != null)
      error_message = "`onboard_monitoring` requires both `monitor_workspace_id` and `log_analytics_workspace_id` (or legacy `oms_agent.log_analytics_workspace_id`)."
    }
    precondition {
      condition     = !var.onboard_alerts || (var.alert_email != null && trimspace(var.alert_email) != "")
      error_message = "`onboard_alerts` requires a non-empty `alert_email`."
    }
    precondition {
      condition     = local.is_automatic || local.automatic_channel_upgrade_check
      error_message = "Either disable automatic upgrades, or specify `kubernetes_version` or `orchestrator_version` only up to the minor version when using `automatic_channel_upgrade=patch`. You don't need to specify `kubernetes_version` at all when using `automatic_channel_upgrade=stable|rapid|node-image`, where `orchestrator_version` always must be set to `null`."
    }
    precondition {
      condition     = local.is_automatic || var.role_based_access_control_enabled || !(var.azure_active_directory_role_based_access_control != null)
      error_message = "Enabling Azure Active Directory integration requires that `role_based_access_control_enabled` be set to true."
    }
    precondition {
      condition     = local.is_automatic || var.key_management_service == null || try(!var.managed_identities.system_assigned, false)
      error_message = "KMS etcd encryption doesn't work with system-assigned managed identity."
    }
    precondition {
      condition     = local.is_automatic || !var.workload_identity_enabled || var.oidc_issuer_enabled
      error_message = "`oidc_issuer_enabled` must be set to `true` to enable Azure AD Workload Identity"
    }
    precondition {
      condition     = local.is_automatic || (var.dns_prefix != null) != (var.dns_prefix_private_cluster != null)
      error_message = "Exactly one of `dns_prefix` or `dns_prefix_private_cluster` must be specified (non-null and non-empty)."
    }
    precondition {
      condition     = local.is_automatic || (var.dns_prefix_private_cluster == null) || (var.private_dns_zone_id != null)
      error_message = "When `dns_prefix_private_cluster` is set, `private_dns_zone_id` must be set."
    }
    precondition {
      condition     = local.is_automatic || var.automatic_upgrade_channel != "node-image" || var.node_os_channel_upgrade == "NodeImage"
      error_message = "`node_os_channel_upgrade` must be set to `NodeImage` if `automatic_channel_upgrade` has been set to `node-image`."
    }
    precondition {
      condition     = local.is_automatic || var.node_pools == null || var.default_node_pool.type == "VirtualMachineScaleSets"
      error_message = "The 'type' variable must be set to 'VirtualMachineScaleSets' if 'node_pools' is not null."
    }
  }
}

moved {
  from = azurerm_kubernetes_cluster.this
  to   = azapi_resource.this
}

# Retrieve kubeconfig(s) & full cluster for outputs
resource "azapi_resource_action" "this_user_kubeconfig" {
  count = local.is_automatic ? 0 : 1

  action                 = "listClusterUserCredential"
  method                 = "POST"
  resource_id            = azapi_resource.this.id
  type                   = azapi_resource.this.type
  response_export_values = ["kubeconfigs"]
}

resource "azapi_resource_action" "this_admin_kubeconfig" {
  count = local.is_automatic ? 0 : 1

  action                 = "listClusterAdminCredential"
  method                 = "POST"
  resource_id            = azapi_resource.this.id
  type                   = azapi_resource.this.type
  response_export_values = ["kubeconfigs"]
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

resource "random_string" "dns_prefix" {
  length  = 10
  lower   = true
  numeric = true
  special = false
  upper   = false
}
