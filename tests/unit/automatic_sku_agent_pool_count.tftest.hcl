mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location  = "eastus"
  name      = "test-aks"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
}

run "automatic_sku_includes_agent_pool_count_when_autoscaling_is_set" {
  command = plan

  variables {
    sku = {
      name = "Automatic"
      tier = "Free"
    }
    default_agent_pool = {
      count_of            = 1
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 3
      vnet_subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/subnet-test"
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.agentPoolProfiles[0].count == 1
    error_message = "agentPoolProfiles[0].count should be present and derived from default_agent_pool.count_of."
  }
}

run "base_sku_includes_agent_pool_count_when_autoscaling_is_set" {
  command = plan

  variables {
    sku = {
      name = "Base"
      tier = "Free"
    }
    default_agent_pool = {
      count_of            = 1
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 3
      vnet_subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/subnet-test"
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.agentPoolProfiles[0].count == 1
    error_message = "For Base SKU, agentPoolProfiles[0].count should be present and derived from default_agent_pool.count_of."
  }
}
