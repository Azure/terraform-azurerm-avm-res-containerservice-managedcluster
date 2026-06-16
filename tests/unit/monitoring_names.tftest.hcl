mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

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
  location                = "eastus2"
  name                    = "aks-short"
  onboard_monitoring      = true
  parent_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  prometheus_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Monitor/accounts/prom-test"
}

run "short_cluster_names_keep_legacy_monitoring_names" {
  command = plan

  assert {
    condition     = module.monitoring[0].data_collection_endpoint_name == "MSProm-eastus2-aks-short"
    error_message = "Short cluster names should keep the existing MSProm data collection endpoint name."
  }

  assert {
    condition     = module.monitoring[0].data_collection_rule_name == module.monitoring[0].data_collection_endpoint_name
    error_message = "The MSProm data collection rule should keep matching the data collection endpoint name."
  }
}

run "long_cluster_names_are_capped_for_monitoring_resources" {
  command = plan

  variables {
    name = "aks-crucio-epe-argo-tenant-itt-eastus2-dev"
  }

  assert {
    condition     = length(module.monitoring[0].data_collection_endpoint_name) <= 44
    error_message = "The MSProm data collection endpoint name must not exceed Azure's 44 character limit."
  }

  assert {
    condition     = startswith(module.monitoring[0].data_collection_endpoint_name, "MSProm-eastus2-")
    error_message = "The truncated MSProm data collection endpoint name should preserve the existing prefix."
  }

  assert {
    condition     = module.monitoring[0].data_collection_rule_name == module.monitoring[0].data_collection_endpoint_name
    error_message = "The MSProm data collection rule should use the same capped name as the endpoint."
  }

  assert {
    condition     = !strcontains(module.monitoring[0].data_collection_endpoint_name, "--") && !endswith(module.monitoring[0].data_collection_endpoint_name, "-")
    error_message = "The capped MSProm data collection endpoint name must not contain consecutive hyphens or end with a hyphen."
  }
}