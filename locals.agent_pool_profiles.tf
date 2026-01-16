# This file contains local values for agent pool profiles in an AKS cluster.
# It differentiates between automatic and standard agent pools based on the SKU.
# Automatic agent pools have a predefined set of properties, while standard agent pools include all properties.
locals {
  agent_pool_profiles = [{
    for k, v in module.default_agent_pool.body_properties : k => v if can(regex(local.agent_pool_profiles_regex, k))
  }]
  agent_pool_properties_automatic = [
    "name",
    "mode",
    "count",
    "vnetSubnetID",
    "tags",
  ]
  agent_pool_profiles_regex_standard  = "^(.*)$"
  agent_pool_profiles_regex_automatic = "^(${join("|", local.agent_pool_properties_automatic)})$"
  agent_pool_profiles_regex           = local.is_automatic ? local.agent_pool_profiles_regex_automatic : local.agent_pool_profiles_regex_standard
}
