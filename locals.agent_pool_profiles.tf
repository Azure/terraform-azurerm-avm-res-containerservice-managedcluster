# This file contains local values for agent pool profiles in an AKS cluster.
# It differentiates between automatic and standard agent pools based on the SKU.
# Automatic agent pools have a predefined set of properties, while standard agent pools include all properties.
# Why regex? Because Terraform required that ternary expressions return the same type.
# This is also try for functions like concat(), etc.
# Therefore, we use regex to filter the properties accordingly.
# The only ternary we use is a string for the regex pattern.
locals {
  # We only care about the first agent pool. The others are created using child resources.
  agent_pool_profiles = [
    merge(
      {
        for k, v in module.default_agent_pool_data.body_properties : k => v if can(regex(local.agent_pool_profiles_regex, k)) && v != null
      },
      {
        name = module.default_agent_pool_data.name
      }
    )
  ]
  agent_pool_profiles_regex           = local.is_automatic ? local.agent_pool_profiles_regex_automatic : local.agent_pool_profiles_regex_standard
  agent_pool_profiles_regex_automatic = "^(${join("|", local.agent_pool_properties_automatic)})$"
  agent_pool_profiles_regex_standard  = "^(.*)$"
  agent_pool_properties_automatic = [
    "name",
    "mode",
    "count",
    "vnetSubnetID",
    "tags",
  ]
}
