mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location  = "eastus"
  name      = "test-aks"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
}

# When the flag is false, the child module for the default agent pool is not instantiated.
run "default_agent_pool_child_not_instantiated_when_flag_false" {
  command = plan

  assert {
    condition     = length(module.default_agent_pool) == 0
    error_message = "module.default_agent_pool must have count 0 when default_agent_pool_managed_as_child is false."
  }
}

# Validation rejects a default agent pool name longer than 8 characters when the flag is
# true, because the create_before_destroy rename pattern appends a 4-character suffix and
# the Azure node-pool name limit is 12 characters.
run "default_agent_pool_name_too_long_rejected_when_managed_as_child" {
  command = plan

  variables {
    default_agent_pool_managed_as_child = true
    default_agent_pool = {
      name    = "toolongname"
      vm_size = "Standard_D2ds_v5"
    }
  }

  expect_failures = [
    var.default_agent_pool_managed_as_child,
  ]
}
