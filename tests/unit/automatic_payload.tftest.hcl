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

run "automatic_autoscaling_default_pool_keeps_create_count" {
  command = plan

  variables {
    default_agent_pool = {
      count_of            = 1
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 3
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.agentPoolProfiles[0].count == 1
    error_message = "Automatic cluster create payload should include the default agent pool count even when autoscaling is configured."
  }
}

run "automatic_cluster_supported_profiles_are_passed_through" {
  command = plan

  variables {
    aad_profile = {
      admin_group_object_ids = ["00000000-0000-0000-0000-000000000001"]
      enable_azure_rbac      = true
      managed                = true
    }
    auto_upgrade_profile = {
      node_os_upgrade_channel = "NodeImage"
      upgrade_channel         = "stable"
    }
    node_provisioning_profile = {
      default_node_pools = "Auto"
      mode               = "Auto"
    }
    oidc_issuer_profile = {
      enabled = true
    }
    security_profile = {
      image_cleaner = {
        enabled        = true
        interval_hours = 48
      }
      workload_identity = {
        enabled = true
      }
    }
    workload_auto_scaler_profile = {
      keda = {
        enabled = true
      }
      vertical_pod_autoscaler = {
        enabled = true
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.aadProfile.adminGroupObjectIDs[0] == "00000000-0000-0000-0000-000000000001"
    error_message = "Automatic cluster payload should pass through aadProfile admin groups."
  }

  assert {
    condition     = azapi_resource.this.body.properties.autoUpgradeProfile.upgradeChannel == "stable"
    error_message = "Automatic cluster payload should pass through autoUpgradeProfile."
  }

  assert {
    condition     = azapi_resource.this.body.properties.nodeProvisioningProfile.mode == "Auto"
    error_message = "Automatic cluster payload should pass through nodeProvisioningProfile."
  }

  assert {
    condition     = azapi_resource.this.body.properties.oidcIssuerProfile.enabled == true
    error_message = "Automatic cluster payload should pass through oidcIssuerProfile."
  }

  assert {
    condition     = azapi_resource.this.body.properties.securityProfile.workloadIdentity.enabled == true
    error_message = "Automatic cluster payload should pass through securityProfile."
  }

  assert {
    condition     = azapi_resource.this.body.properties.workloadAutoScalerProfile.keda.enabled == true
    error_message = "Automatic cluster payload should pass through workloadAutoScalerProfile."
  }
}
