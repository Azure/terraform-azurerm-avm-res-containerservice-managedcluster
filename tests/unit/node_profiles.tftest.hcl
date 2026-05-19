mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location  = "eastus"
  name      = "test-aks"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
}

run "null_node_profiles_are_omitted" {
  command = plan

  variables {
    node_provisioning_profile   = null
    node_resource_group_profile = null
  }

  assert {
    condition     = !can(azapi_resource.this.body.properties.nodeProvisioningProfile)
    error_message = "nodeProvisioningProfile should be omitted when node_provisioning_profile is null."
  }

  assert {
    condition     = !can(azapi_resource.this.body.properties.nodeResourceGroupProfile)
    error_message = "nodeResourceGroupProfile should be omitted when node_resource_group_profile is null."
  }
}

run "valid_node_profiles_are_included" {
  command = plan

  variables {
    node_provisioning_profile = {
      default_node_pools = "None"
      mode               = "Manual"
    }
    node_resource_group_profile = {
      restriction_level = "ReadOnly"
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.nodeProvisioningProfile.defaultNodePools == "None"
    error_message = "nodeProvisioningProfile.defaultNodePools should use the provided value."
  }

  assert {
    condition     = azapi_resource.this.body.properties.nodeProvisioningProfile.mode == "Manual"
    error_message = "nodeProvisioningProfile.mode should use the provided value."
  }

  assert {
    condition     = azapi_resource.this.body.properties.nodeResourceGroupProfile.restrictionLevel == "ReadOnly"
    error_message = "nodeResourceGroupProfile.restrictionLevel should use the provided value."
  }
}

run "invalid_node_provisioning_default_node_pools_fails" {
  command = plan

  variables {
    node_provisioning_profile = {
      default_node_pools = "Invalid"
    }
  }

  expect_failures = [
    var.node_provisioning_profile,
  ]
}

run "invalid_node_provisioning_mode_fails" {
  command = plan

  variables {
    node_provisioning_profile = {
      mode = "Invalid"
    }
  }

  expect_failures = [
    var.node_provisioning_profile,
  ]
}

run "invalid_node_resource_group_restriction_level_fails" {
  command = plan

  variables {
    node_resource_group_profile = {
      restriction_level = "Invalid"
    }
  }

  expect_failures = [
    var.node_resource_group_profile,
  ]
}
