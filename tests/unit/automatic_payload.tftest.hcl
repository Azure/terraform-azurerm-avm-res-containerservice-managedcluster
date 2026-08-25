mock_provider "azapi" {}
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

# API 2026-03-01 lets AKS Automatic manage system pools without agentPoolProfiles.
run "automatic_cluster_omits_default_agent_pool" {
  command = plan

  assert {
    condition     = !contains(keys(azapi_resource.this.body.properties), "agentPoolProfiles")
    error_message = "Automatic cluster payload should omit agentPoolProfiles."
  }

  assert {
    condition     = length(azapi_update_resource.default_agent_pool) == 0
    error_message = "Automatic clusters should not update an explicit default agent pool."
  }
}

run "automatic_cluster_ignores_default_agent_pool_configuration" {
  command = plan

  variables {
    default_agent_pool = {
      count_of            = 1
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 3
      vnet_subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet/subnets/nodes"
      upgrade_settings = {
        drain_timeout_in_minutes      = 30
        node_soak_duration_in_minutes = 15
      }
    }
  }

  assert {
    condition     = !contains(keys(azapi_resource.this.body.properties), "agentPoolProfiles")
    error_message = "Automatic cluster payload should omit agentPoolProfiles even when default_agent_pool is configured."
  }

  assert {
    condition     = length(azapi_update_resource.default_agent_pool) == 0
    error_message = "Automatic clusters should not update an explicit default agent pool when default_agent_pool is configured."
  }
}

run "standard_cluster_retains_implicit_default_pool" {
  command = plan

  variables {
    sku = {
      name = "Base"
      tier = "Free"
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.agentPoolProfiles[0].name == "systempool"
    error_message = "Non-Automatic clusters should retain the implicit systempool when default_agent_pool is not configured."
  }

  assert {
    condition     = azapi_resource.this.body.properties.agentPoolProfiles[0].count == 3
    error_message = "The implicit default agent pool should retain its default node count."
  }

  assert {
    condition     = length(azapi_update_resource.default_agent_pool) == 1
    error_message = "Non-Automatic clusters should retain the default agent pool update."
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

run "automatic_cluster_pod_cidr_is_passed_through" {
  command = plan

  variables {
    network_profile = {
      outbound_type = "managedNATGateway"
      pod_cidr      = "172.28.0.0/16"
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.podCidr == "172.28.0.0/16"
    error_message = "Automatic cluster payload should pass through networkProfile.podCidr."
  }
}

run "automatic_cluster_load_balancer_omits_network_profile" {
  command = plan

  variables {
    network_profile = {
      outbound_type = "loadBalancer"
      pod_cidr      = "172.28.0.0/16"
    }
  }

  assert {
    condition     = !can(azapi_resource.this.body.properties.networkProfile)
    error_message = "Automatic cluster payload should omit networkProfile when outboundType is loadBalancer."
  }
}
