mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location  = "eastus"
  name      = "test-aks"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  sku = {
    name = "Base"
    tier = "Standard"
  }
}

# Regression test for the agent pool update payload.
#
# The default agent pool is updated via `azapi_update_resource.default_agent_pool`, whose
# body is assembled by stripping null attributes from each nested object. A previous
# implementation wrapped those objects with `coalesce(obj, {})`, which unified the populated
# object with the empty object `{}` to `map(string)` and silently coerced numeric attributes
# (drainTimeoutInMinutes / nodeSoakDurationInMinutes) into strings. The AKS API then rejected
# the request with "drainTimeoutInMinutes accept type int32, not type string".
#
# These assertions fail if the numeric upgrade settings are serialized as strings.
run "default_agent_pool_upgrade_settings_keep_numeric_types" {
  command = plan

  variables {
    default_agent_pool = {
      name    = "systempool"
      vm_size = "Standard_D4ads_v6"
      upgrade_settings = {
        drain_timeout_in_minutes      = 30
        max_surge                     = "35%"
        node_soak_duration_in_minutes = 15
      }
    }
  }

  # Number equality is type-aware in HCL ("30" == 30 is false), so these fail if coerced.
  assert {
    condition     = azapi_update_resource.default_agent_pool.body.properties.upgradeSettings.drainTimeoutInMinutes == 30
    error_message = "drainTimeoutInMinutes must stay an int32 in the agent pool update payload, not be coerced to a string."
  }

  assert {
    condition     = azapi_update_resource.default_agent_pool.body.properties.upgradeSettings.nodeSoakDurationInMinutes == 15
    error_message = "nodeSoakDurationInMinutes must stay an int32 in the agent pool update payload, not be coerced to a string."
  }

  # Belt and suspenders: a number serializes as `30`, a string as `"30"`.
  assert {
    condition     = strcontains(jsonencode(azapi_update_resource.default_agent_pool.body.properties.upgradeSettings), "\"drainTimeoutInMinutes\":30")
    error_message = "drainTimeoutInMinutes must serialize as a JSON number, not a quoted string."
  }

  # String-typed sibling attribute must remain a string.
  assert {
    condition     = azapi_update_resource.default_agent_pool.body.properties.upgradeSettings.maxSurge == "35%"
    error_message = "maxSurge must stay a string in the agent pool update payload."
  }
}
