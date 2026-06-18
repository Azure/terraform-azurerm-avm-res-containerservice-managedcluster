mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-aks"
      output = {
        properties = {
          addonProfiles = {
            ingressApplicationGateway = {
              identity = {
                objectId = "00000000-0000-0000-0000-000000000001"
              }
            }
          }
          nodeResourceGroup = "MC_rg-test_test-aks_eastus"
        }
      }
    }
  }
}
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

run "restored_outputs_are_available" {
  command = apply

  assert {
    condition     = contains(azapi_resource.this.response_export_values, "properties.addonProfiles.ingressApplicationGateway.identity")
    error_message = "The managed cluster response exports should include the Ingress Application Gateway identity."
  }

  assert {
    condition     = output.ingress_app_object_id == "00000000-0000-0000-0000-000000000001"
    error_message = "ingress_app_object_id should return the Ingress Application Gateway identity objectId."
  }

  assert {
    condition     = output.node_resource_group_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MC_rg-test_test-aks_eastus"
    error_message = "node_resource_group_id should return the node resource group resource ID."
  }

  assert {
    condition     = output.data_collection_endpoint_id == null
    error_message = "data_collection_endpoint_id should be null when monitoring is not onboarded."
  }

  assert {
    condition     = output.data_collection_endpoint_name == null
    error_message = "data_collection_endpoint_name should be null when monitoring is not onboarded."
  }
}

run "monitoring_outputs_are_available" {
  command = apply

  variables {
    addon_profile_oms_agent = {
      enabled = true
      config = {
        log_analytics_workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
      }
    }
    azure_monitor_profile = {
      metrics = {
        enabled = true
      }
    }
    onboard_monitoring      = true
    prometheus_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Monitor/accounts/prom-test"
  }

  assert {
    condition     = output.data_collection_endpoint_id == module.monitoring[0].data_collection_endpoint_id
    error_message = "data_collection_endpoint_id should expose the monitoring submodule data collection endpoint ID."
  }

  assert {
    condition     = output.data_collection_endpoint_name == "MSProm-eastus-test-aks"
    error_message = "data_collection_endpoint_name should expose the monitoring submodule data collection endpoint name."
  }
}
