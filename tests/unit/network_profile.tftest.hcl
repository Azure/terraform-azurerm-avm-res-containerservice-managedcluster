mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test-aks"
    }
  }
  mock_resource "azapi_resource_action" {
    defaults = {
      output = {
        kubeconfigs = [{
          value = base64encode(jsonencode({
            clusters = [{ cluster = { certificate-authority-data = "test-ca" } }]
          }))
        }]
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "random" {}

variables {
  location  = "westeurope"
  name      = "test-aks"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
}

run "advanced_networking_is_serialized" {
  command = plan

  variables {
    network_profile = {
      outbound_type       = "userDefinedRouting"
      dns_service_ip      = "192.168.129.10"
      service_cidr        = "192.168.128.0/18"
      pod_cidr            = "192.168.0.0/17"
      network_plugin      = "azure"
      network_plugin_mode = "overlay"
      network_dataplane   = "cilium"
      network_policy      = "cilium"
      load_balancer_sku   = "standard"
      advanced_networking = {
        enabled = true
        observability = {
          enabled = true
        }
        performance = {
          acceleration_mode = "BpfVeth"
        }
        security = {
          enabled                   = true
          advanced_network_policies = "FQDN"
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.advancedNetworking.enabled
    error_message = "networkProfile.advancedNetworking.enabled should serialize true."
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.advancedNetworking.observability.enabled
    error_message = "Advanced Networking observability should serialize as enabled."
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.advancedNetworking.performance.accelerationMode == "BpfVeth"
    error_message = "Advanced Networking performance acceleration should serialize using the ARM property name."
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.advancedNetworking.security.enabled
    error_message = "Advanced Networking security should serialize as enabled."
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.advancedNetworking.security.advancedNetworkPolicies == "FQDN"
    error_message = "Advanced Networking security policies should serialize using the ARM property name."
  }
}

run "advanced_networking_rejects_invalid_acceleration_mode" {
  command = plan

  variables {
    network_profile = {
      advanced_networking = {
        performance = {
          acceleration_mode = "Invalid"
        }
      }
    }
  }

  expect_failures = [
    var.network_profile,
  ]
}

run "advanced_networking_acceleration_can_be_disabled" {
  command = apply

  variables {
    network_profile = {
      advanced_networking = {
        performance = {
          acceleration_mode = "None"
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.advancedNetworking.performance.accelerationMode == "None"
    error_message = "The supported None value must be retained rather than treated as an omitted setting."
  }
}

run "advanced_networking_performance_can_be_omitted" {
  command = apply

  variables {
    network_profile = {
      advanced_networking = {
        enabled = true
        observability = {
          enabled = true
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.advancedNetworking.performance == null
    error_message = "Existing Advanced Networking configurations must not implicitly enable performance acceleration."
  }
}

run "advanced_networking_acceleration_mode_can_be_omitted" {
  command = apply

  variables {
    network_profile = {
      advanced_networking = {
        performance = {}
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.advancedNetworking.performance.accelerationMode == null
    error_message = "An empty performance object must not impose an acceleration mode."
  }
}
