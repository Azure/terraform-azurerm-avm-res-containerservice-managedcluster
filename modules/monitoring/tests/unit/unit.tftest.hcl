mock_provider "azapi" {}

variables {
  aks_cluster_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/aks-short"
  location                   = "eastus2"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
  parent_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  prometheus_workspace_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Monitor/accounts/prom-test"
}

run "short_cluster_names_keep_legacy_names" {
  command = plan

  assert {
    condition     = azapi_resource.dce_msprom.name == "MSProm-eastus2-aks-short"
    error_message = "Short cluster names should keep the existing MSProm data collection endpoint name."
  }

  assert {
    condition     = azapi_resource.dcr_msprom.name == azapi_resource.dce_msprom.name
    error_message = "The MSProm data collection rule should keep matching the data collection endpoint name."
  }
}

run "long_cluster_names_are_capped_for_monitoring_resources" {
  command = plan

  variables {
    aks_cluster_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/aks-crucio-epe-argo-tenant-itt-eastus2-dev"
  }

  assert {
    condition     = length(azapi_resource.dce_msprom.name) <= 44
    error_message = "The MSProm data collection endpoint name must not exceed Azure's 44 character limit."
  }

  assert {
    condition     = startswith(azapi_resource.dce_msprom.name, "MSProm-eastus2-")
    error_message = "The truncated MSProm data collection endpoint name should preserve the existing prefix."
  }

  assert {
    condition     = azapi_resource.dcr_msprom.name == azapi_resource.dce_msprom.name
    error_message = "The MSProm data collection rule should use the same capped name as the endpoint."
  }

  assert {
    condition     = !strcontains(azapi_resource.dce_msprom.name, "--") && !endswith(azapi_resource.dce_msprom.name, "-")
    error_message = "The capped MSProm data collection endpoint name must not contain consecutive hyphens or end with a hyphen."
  }
}

run "maximum_cluster_names_keep_non_msprom_names_unchanged" {
  command = plan

  variables {
    aks_cluster_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/aks-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }

  assert {
    condition     = azapi_resource.dcr_msprom_aks.name == "dcr-aks-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    error_message = "The surgical MSProm fix should not change the MSProm data collection rule association name."
  }

  assert {
    condition     = azapi_resource.dcr_msci_aks.name == "msci-aks-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    error_message = "The surgical MSProm fix should not change the MSCI data collection rule association name."
  }

  assert {
    condition     = azapi_resource.dcr_msci.name == "MSCI-eastus2-aks-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    error_message = "The surgical MSProm fix should not change the MSCI data collection rule name."
  }
}
