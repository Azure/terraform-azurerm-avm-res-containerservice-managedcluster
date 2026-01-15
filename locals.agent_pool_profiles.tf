# This file contains local values for agent pool profiles in an AKS cluster.
# It differentiates between automatic and standard agent pools based on the SKU.
# Automatic agent pools have a predefined set of properties, while standard agent pools include all properties.
locals {
  agent_pool_properties_automatic = [
    "name",
    "mode",
    "count",
    "vnetSubnetID",
    "tags",
  ]
  agent_pool_profiles_automatic = local.is_automatic ? [
    {
      for k, v in module.default_agent_pool.body_properties : k => v if contains(local.agent_pool_properties_automatic, k) && !(can(v == null) && v == null)
    }
  ] : []
  agent_pool_profiles = concat(local.agent_pool_profiles_automatic, local.agent_pool_profiles_standard)
  agent_pool_profiles_standard = local.is_automatic ? [] : [
    {
      for k, v in module.default_agent_pool.body_properties : k => v if !(can(v == null) && v == null)
    }
  ]
}
