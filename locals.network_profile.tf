locals {
  network_profile = (
    (local.is_automatic && try(var.network_profile.outbound_type == "loadBalancer", true))
    ||
    local.network_profile_filtered == null
  ) ? null : { for k, v in local.network_profile_filtered : k => v if v != null }
  network_profile_filtered = var.network_profile == null ? null : { for k, v in local.network_profile_full : k => v if can(regex(local.network_profile_properties_regex, k)) && v != null }
  network_profile_full = var.network_profile == null ? null : {
    advancedNetworking = var.network_profile.advanced_networking == null ? null : {
      enabled = var.network_profile.advanced_networking.enabled
      observability = var.network_profile.advanced_networking.observability == null ? null : {
        enabled = var.network_profile.advanced_networking.observability.enabled
      }
      security = var.network_profile.advanced_networking.security == null ? null : {
        advancedNetworkPolicies = var.network_profile.advanced_networking.security.advanced_network_policies
        enabled                 = var.network_profile.advanced_networking.security.enabled
      }
    }
    dnsServiceIP = var.network_profile.dns_service_ip
    ipFamilies   = var.network_profile.ip_families == null ? null : [for item in var.network_profile.ip_families : item]
    loadBalancerProfile = var.network_profile.load_balancer_profile == null ? null : {
      allocatedOutboundPorts              = var.network_profile.load_balancer_profile.allocated_outbound_ports
      backendPoolType                     = var.network_profile.load_balancer_profile.backend_pool_type
      enableMultipleStandardLoadBalancers = var.network_profile.load_balancer_profile.enable_multiple_standard_load_balancers
      idleTimeoutInMinutes                = var.network_profile.load_balancer_profile.idle_timeout_in_minutes
      managedOutboundIPs = var.network_profile.load_balancer_profile.managed_outbound_ips == null ? null : {
        count     = var.network_profile.load_balancer_profile.managed_outbound_ips.count
        countIPv6 = var.network_profile.load_balancer_profile.managed_outbound_ips.count_i_pv6
      }
      outboundIPPrefixes = var.network_profile.load_balancer_profile.outbound_ip_prefixes == null ? null : {
        publicIPPrefixes = var.network_profile.load_balancer_profile.outbound_ip_prefixes.public_ip_prefixes == null ? null : [for item in var.network_profile.load_balancer_profile.outbound_ip_prefixes.public_ip_prefixes : item == null ? null : {
          id = item.id
        }]
      }
      outboundIPs = var.network_profile.load_balancer_profile.outbound_ips == null ? null : {
        publicIPs = var.network_profile.load_balancer_profile.outbound_ips.public_ips == null ? null : [for item in var.network_profile.load_balancer_profile.outbound_ips.public_ips : item == null ? null : {
          id = item.id
        }]
      }
    }
    loadBalancerSku = var.network_profile.load_balancer_sku
    natGatewayProfile = var.network_profile.nat_gateway_profile == null ? null : {
      idleTimeoutInMinutes = var.network_profile.nat_gateway_profile.idle_timeout_in_minutes
      managedOutboundIPProfile = var.network_profile.nat_gateway_profile.managed_outbound_ip_profile == null ? null : {
        count = var.network_profile.nat_gateway_profile.managed_outbound_ip_profile.count
      }
    }
    networkDataplane  = var.network_profile.network_dataplane
    networkMode       = var.network_profile.network_mode
    networkPlugin     = var.network_profile.network_plugin
    networkPluginMode = var.network_profile.network_plugin_mode
    networkPolicy     = var.network_profile.network_policy
    outboundType      = var.network_profile.outbound_type
    podCidr           = var.network_profile.pod_cidr
    podCidrs          = var.network_profile.pod_cidrs == null ? null : [for item in var.network_profile.pod_cidrs : item]
    serviceCidr       = var.network_profile.service_cidr
    serviceCidrs      = var.network_profile.service_cidrs == null ? null : [for item in var.network_profile.service_cidrs : item]
    staticEgressGatewayProfile = var.network_profile.static_egress_gateway_profile == null ? null : {
      enabled = var.network_profile.static_egress_gateway_profile.enabled
    }
  }
  network_profile_properties_automatic = [
    "dnsServiceIP",
    "outboundType",
    "serviceCidr"
  ]
  network_profile_properties_regex           = local.is_automatic ? local.network_profile_properties_regex_automatic : local.network_profile_properties_regex_standard
  network_profile_properties_regex_automatic = "^(${join("|", local.network_profile_properties_automatic)})$"
  network_profile_properties_regex_standard  = "^(.*)$"
}
