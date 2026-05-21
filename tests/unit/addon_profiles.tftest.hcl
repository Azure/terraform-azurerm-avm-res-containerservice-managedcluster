mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location  = "eastus"
  name      = "test-aks"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
}

run "azure_policy_config_is_passed_through" {
  command = plan

  variables {
    addon_profile_azure_policy = {
      enabled = true
      config = {
        version = "v2"
      }
    }
  }

  assert {
    condition     = try(azapi_resource.this.body.properties.addonProfiles.azurepolicy.config.version, null) == "v2"
    error_message = "Azure Policy addon config should be passed through to the managed cluster addon profile."
  }
}
