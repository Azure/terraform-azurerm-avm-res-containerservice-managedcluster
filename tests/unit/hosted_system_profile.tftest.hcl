mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location  = "eastus"
  name      = "test-aks"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  sku = {
    name = "Automatic"
    tier = "Standard"
  }
}

run "hosted_system_profile_omitted_when_null" {
  command = plan

  assert {
    condition     = !can(azapi_resource.this.body.properties.hostedSystemProfile)
    error_message = "hostedSystemProfile must be omitted from the payload when hosted_system_profile is null."
  }
}

run "hosted_system_profile_serializes_subnet_ids" {
  command = plan

  variables {
    hosted_system_profile = {
      enabled               = true
      node_subnet_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/nodes"
      system_node_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/system"
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.hostedSystemProfile.enabled == true
    error_message = "hostedSystemProfile.enabled should be serialized."
  }

  assert {
    condition     = azapi_resource.this.body.properties.hostedSystemProfile.nodeSubnetID == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/nodes"
    error_message = "hostedSystemProfile.nodeSubnetID should match the provided node_subnet_id."
  }

  assert {
    condition     = azapi_resource.this.body.properties.hostedSystemProfile.systemNodeSubnetID == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/system"
    error_message = "hostedSystemProfile.systemNodeSubnetID should match the provided system_node_subnet_id."
  }
}

run "hosted_system_profile_requires_subnet_ids_when_enabled" {
  command = plan

  variables {
    hosted_system_profile = {
      enabled = true
    }
  }

  expect_failures = [
    var.hosted_system_profile,
  ]
}

run "hosted_system_profile_rejects_non_automatic_sku" {
  command = plan

  variables {
    sku = {
      name = "Base"
      tier = "Standard"
    }
    hosted_system_profile = {
      enabled               = true
      node_subnet_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/nodes"
      system_node_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/system"
    }
  }

  expect_failures = [
    var.hosted_system_profile,
  ]
}
