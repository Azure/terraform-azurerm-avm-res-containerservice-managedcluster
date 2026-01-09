locals {
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
      advancedNetworking  = local.advanced_networking
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
}
