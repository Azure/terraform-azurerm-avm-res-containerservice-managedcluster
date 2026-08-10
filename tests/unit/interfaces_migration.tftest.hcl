mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-aks"
      output = {
        properties = {
          nodeResourceGroup = "MC_rg-test_test-aks_eastus"
        }
      }
    }
  }
  mock_resource "azapi_resource_action" {
    defaults = {
      output = {
        kubeconfigs = [{
          value = "eyJjbHVzdGVycyI6W3siY2x1c3RlciI6eyJjZXJ0aWZpY2F0ZS1hdXRob3JpdHktZGF0YSI6ImRHVnpkQT09In19XX0="
        }]
      }
    }
  }
}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {
  mock_resource "random_uuid" {
    defaults = {
      result = "11111111-1111-1111-1111-111111111111"
    }
  }
}

variables {
  location  = "eastus"
  name      = "test-aks"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  diagnostic_settings = {
    primary = {
      name                  = "diag-test"
      log_categories        = ["kube-audit"]
      log_groups            = []
      metric_categories     = ["AllMetrics"]
      workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
    }
  }
  role_assignments = {
    reader = {
      principal_id               = "22222222-2222-2222-2222-222222222222"
      role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    }
  }
}

run "legacy_diagnostics_are_adapted_to_v2" {
  command = plan

  assert {
    condition     = module.interfaces.diagnostic_settings_azapi_v2["primary"].name == "diag-test"
    error_message = "The adapter must preserve the diagnostic setting name."
  }

  assert {
    condition     = module.interfaces.diagnostic_settings_azapi_v2["primary"].body.properties.logs[0].category == "kube-audit"
    error_message = "The adapter must map legacy log categories to v2 log entries."
  }

  assert {
    condition     = module.interfaces.diagnostic_settings_azapi_v2["primary"].body.properties.metrics[0].category == "AllMetrics"
    error_message = "The adapter must map legacy metric categories to v2 metric entries."
  }
}

run "role_assignment_name_is_preserved" {
  command = apply

  assert {
    condition     = azurerm_role_assignment.this["reader"].name == "11111111-1111-1111-1111-111111111111"
    error_message = "The AzureRM role assignment must use the utility module's retained UUID."
  }
}
