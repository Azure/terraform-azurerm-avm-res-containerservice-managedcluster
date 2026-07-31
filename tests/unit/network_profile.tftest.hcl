mock_provider "azapi" {}
mock_provider "modtm" {}
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
    condition     = azapi_resource.this.body.properties.networkProfile.advancedNetworking.security.enabled
    error_message = "Advanced Networking security should serialize as enabled."
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.advancedNetworking.security.advancedNetworkPolicies == "FQDN"
    error_message = "Advanced Networking security policies should serialize using the ARM property name."
  }
}
