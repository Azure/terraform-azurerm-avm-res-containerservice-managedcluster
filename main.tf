data "azurerm_client_config" "current" {}

# Locals for network profile (moved out of resource body to simplify expressions)
locals {
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
}

resource "azapi_resource" "this" {
  location  = var.location
  name      = "${var.name}${var.cluster_suffix}"
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.ContainerService/managedClusters@2025-07-01"

  # temporary until azapi adds support for 2025-07-01
  schema_validation_enabled = false

  body = {
    properties = {
      kubernetesVersion = var.kubernetes_version
      dnsPrefix         = var.dns_prefix
      apiServerAccessProfile = (var.api_server_access_profile != null || var.private_cluster_enabled) ? {
        authorizedIPRanges   = try(var.api_server_access_profile.authorized_ip_ranges, null)
        enablePrivateCluster = var.private_cluster_enabled
        privateDnsZoneId     = var.private_cluster_enabled ? var.private_dns_zone_id : null
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
      addonProfiles = {
        azurepolicy = var.azure_policy_enabled ? { enabled = true } : null
      }
      agentPoolProfiles = [
        {
          name              = var.default_node_pool.name
          osType            = "Linux"
          mode              = "System"
          vmSize            = var.default_node_pool.vm_size
          count             = var.default_node_pool.node_count
          enableAutoScaling = var.default_node_pool.auto_scaling_enabled
          minCount          = var.default_node_pool.min_count
          maxCount          = var.default_node_pool.max_count
          type              = var.default_node_pool.type
          vnetSubnetID      = var.default_node_pool.vnet_subnet_id
        }
      ]
      networkProfile = local.network_profile_map
    }
  }

  response_export_values = [
    "properties.oidcIssuerProfile.issuerURL",
    "properties.identityProfile",
    "properties.nodeResourceGroup"
  ]

  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  tags           = var.tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  identity {
    type         = try(local.managed_identities.system_assigned_user_assigned.this.type, "SystemAssigned")
    identity_ids = try(local.managed_identities.system_assigned_user_assigned.this.user_assigned_resource_ids, null)
  }

  lifecycle {
    ignore_changes = [
      body.properties.kubernetesVersion
    ]

    precondition {
      condition     = var.cost_analysis_enabled != true || (var.sku_tier == "Standard" || var.sku_tier == "Premium")
      error_message = "`sku_tier` must be either `Standard` or `Premium` when cost analysis is enabled."
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
      condition     = var.key_management_service == null || try(!var.managed_identities.system_assigned, false)
      error_message = "KMS etcd encryption doesn't work with system-assigned managed identity."
    }
    precondition {
      condition     = !var.workload_identity_enabled || var.oidc_issuer_enabled
      error_message = "`oidc_issuer_enabled` must be set to `true` to enable Azure AD Workload Identity"
    }
    precondition {
      condition     = (var.dns_prefix != null) != (var.dns_prefix_private_cluster != null)
      error_message = "Exactly one of `dns_prefix` or `dns_prefix_private_cluster` must be specified (non-null and non-empty)."
    }
    precondition {
      condition     = (var.dns_prefix_private_cluster == null) || (var.private_dns_zone_id != null)
      error_message = "When `dns_prefix_private_cluster` is set, `private_dns_zone_id` must be set."
    }
    precondition {
      condition     = var.automatic_upgrade_channel != "node-image" || var.node_os_channel_upgrade == "NodeImage"
      error_message = "`node_os_channel_upgrade` must be set to `NodeImage` if `automatic_channel_upgrade` has been set to `node-image`."
    }
    precondition {
      condition     = var.node_pools == null || var.default_node_pool.type == "VirtualMachineScaleSets"
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
  action                 = "listClusterUserCredential"
  method                 = "POST"
  resource_id            = azapi_resource.this.id
  type                   = azapi_resource.this.type
  response_export_values = ["kubeconfigs"]
}

resource "azapi_resource_action" "this_admin_kubeconfig" {
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
