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
    tier = "Free"
  }
}

run "agent_pool_versions_fall_back_to_kubernetes_version" {
  command = plan

  variables {
    kubernetes_version = "1.34"
    agent_pools = {
      user = {
        name             = "userpool"
        output_data_only = true
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.agentPoolProfiles[0].orchestratorVersion == "1.34"
    error_message = "The default agent pool orchestrator version should fall back to kubernetes_version."
  }

  assert {
    condition     = module.nodepools["user"].body_properties.orchestratorVersion == "1.34"
    error_message = "Additional agent pool orchestrator versions should fall back to kubernetes_version."
  }
}

run "explicit_agent_pool_versions_take_precedence" {
  command = plan

  variables {
    kubernetes_version = "1.34"
    default_agent_pool = {
      orchestrator_version = "1.33"
    }
    agent_pools = {
      user = {
        name                 = "userpool"
        orchestrator_version = "1.32"
        output_data_only     = true
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.agentPoolProfiles[0].orchestratorVersion == "1.33"
    error_message = "An explicit default agent pool orchestrator version should override kubernetes_version."
  }

  assert {
    condition     = module.nodepools["user"].body_properties.orchestratorVersion == "1.32"
    error_message = "An explicit additional agent pool orchestrator version should override kubernetes_version."
  }
}

run "null_versions_preserve_latest_semantics" {
  command = plan

  variables {
    kubernetes_version = null
    agent_pools = {
      user = {
        name             = "userpool"
        output_data_only = true
      }
    }
  }

  assert {
    condition     = try(azapi_resource.this.body.properties.agentPoolProfiles[0].orchestratorVersion, null) == null
    error_message = "The default agent pool orchestrator version should remain null when kubernetes_version is null."
  }

  assert {
    condition     = module.nodepools["user"].body_properties.orchestratorVersion == null
    error_message = "Additional agent pool orchestrator versions should remain null when kubernetes_version is null."
  }
}
