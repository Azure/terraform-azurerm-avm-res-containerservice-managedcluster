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
          # Synthetic kubeconfig containing only a mock CA for the root module outputs.
          value = "eyJjbHVzdGVycyI6W3siY2x1c3RlciI6eyJjZXJ0aWZpY2F0ZS1hdXRob3JpdHktZGF0YSI6Im1vY2sifX1dfQ=="
        }]
      }
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}

run "root_passes_windows2025_to_agent_pool" {
  command = apply

  variables {
    location           = "eastus"
    name               = "test-aks"
    parent_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
    enable_telemetry   = false
    kubernetes_version = "1.35"
    sku = {
      name = "Base"
      tier = "Free"
    }
    agent_pools = {
      windows = {
        name             = "win25"
        enable_fips      = true
        mode             = "User"
        os_sku           = "Windows2025"
        os_type          = "Windows"
        output_data_only = true
      }
    }
  }

  assert {
    condition = (
      module.nodepools["windows"].body_properties.osSKU == "Windows2025" &&
      module.nodepools["windows"].body_properties.osType == "Windows" &&
      module.nodepools["windows"].body_properties.enableFIPS == true &&
      module.nodepools["windows"].body_properties.mode == "User"
    )
    error_message = "The root module must pass Windows2025 and the Windows user-pool settings to the agentpool submodule."
  }
}

run "standalone_agent_pool_supports_windows2025" {
  command = apply

  module {
    source = "./modules/agentpool"
  }

  variables {
    name        = "win25"
    parent_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-aks"
    count_of    = 1
    enable_fips = true
    mode        = "User"
    os_sku      = "Windows2025"
    os_type     = "Windows"
    vm_size     = "Standard_D2s_v5"
  }

  assert {
    condition = (
      azapi_resource.this[0].body.properties.osSKU == "Windows2025" &&
      azapi_resource.this[0].body.properties.osType == "Windows" &&
      azapi_resource.this[0].body.properties.enableFIPS == true
    )
    error_message = "A standalone Windows2025 agent pool must send the OS SKU, Windows OS type, and FIPS setting to Azure."
  }
}

run "windows2022_remains_supported" {
  command = apply

  module {
    source = "./modules/agentpool"
  }

  variables {
    name             = "win22"
    parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-aks"
    os_sku           = "Windows2022"
    os_type          = "Windows"
    output_data_only = true
  }

  assert {
    condition     = output.body_properties.osSKU == "Windows2022"
    error_message = "Adding Windows2025 must preserve Windows2022 support."
  }
}

run "omitted_os_sku_preserves_azure_default" {
  command = apply

  module {
    source = "./modules/agentpool"
  }

  variables {
    name             = "default"
    parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-aks"
    output_data_only = true
  }

  assert {
    condition     = output.body_properties.osSKU == null
    error_message = "An omitted OS SKU must remain null so Azure can choose its default."
  }
}

run "unsupported_os_sku_is_rejected" {
  command = plan

  module {
    source = "./modules/agentpool"
  }

  variables {
    name             = "invalid"
    parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-aks"
    os_sku           = "Windows2099"
    output_data_only = true
  }

  expect_failures = [var.os_sku]
}
