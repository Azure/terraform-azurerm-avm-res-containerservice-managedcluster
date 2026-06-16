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
        for k, v in local.agent_pool_profiles_create_body_properties : k => v if can(regex(local.agent_pool_profiles_regex, k)) && !contains(local.agent_pool_profiles_excluded_properties, k) && k != "securityProfile" && v != null
      },
      {
        # Strip null-valued attributes from each nested object. Do NOT wrap the source with
        # `coalesce(obj, {})`: coalescing a populated object with the empty object `{}`
        # unifies them to `map(string)`, silently coercing numeric attributes (e.g.
        # upgradeSettings.drainTimeoutInMinutes / nodeSoakDurationInMinutes) into strings,
        # which the AKS API rejects ("drainTimeoutInMinutes accept type int32, not type
        # string"). A null-guarding ternary preserves each attribute's original type.
        for k, v in {
          kubeletConfig = try(local.agent_pool_profiles_create_body_properties.kubeletConfig, null) == null ? null : {
            for profile_key, profile_value in local.agent_pool_profiles_create_body_properties.kubeletConfig : profile_key => profile_value if profile_key != "seccompDefault" && profile_value != null
          }
          localDNSProfile = try(local.agent_pool_profiles_create_body_properties.localDNSProfile, null) == null ? null : {
            for profile_key, profile_value in local.agent_pool_profiles_create_body_properties.localDNSProfile : profile_key => profile_value if profile_key != "state" && profile_value != null
          }
          upgradeSettings = try(local.agent_pool_profiles_create_body_properties.upgradeSettings, null) == null ? null : {
            for profile_key, profile_value in local.agent_pool_profiles_create_body_properties.upgradeSettings : profile_key => profile_value if profile_key != "maxBlockedNodes" && profile_value != null
          }
        } : k => v if try(length(v), 0) > 0
      },
      {
        name = module.default_agent_pool_data.name
      }
    )
  ]
  agent_pool_profiles_create_body_properties = merge(
    module.default_agent_pool_data.body_properties,
    {
      count = local.is_automatic ? var.default_agent_pool.count_of : module.default_agent_pool_data.body_properties.count
    }
  )
  agent_pool_profiles_excluded_properties = [
    "artifactStreamingProfile",
    "enableOSDiskFullCaching",
    "kubeletConfig",
    "localDNSProfile",
    "nodeCustomizationProfile",
    "nodeImageVersion",
    "nodeInitializationTaints",
    "securityProfile",
    "upgradeSettings",
    "upgradeSettingsBlueGreen",
    "upgradeStrategy",
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
