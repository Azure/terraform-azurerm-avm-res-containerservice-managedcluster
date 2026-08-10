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
  lock = {
    kind = "CanNotDelete"
    name = "lock-test"
  }
  private_endpoints = {
    primary = {
      application_security_group_associations = {
        primary = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/applicationSecurityGroups/asg-test"
      }
      name                          = "pe-test"
      network_interface_name        = "nic-test"
      private_dns_zone_group_name   = "default"
      private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateDnsZones/privatelink.eastus.azmk8s.io"]
      subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test"
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

  assert {
    condition     = one([for log in module.interfaces.diagnostic_settings_azapi_v2["primary"].body.properties.logs : log.enabled if log.categoryGroup == "audit"]) == false
    error_message = "The adapter must retain the service-normalized disabled audit group."
  }
}

run "role_assignment_name_is_preserved" {
  command = apply

  assert {
    condition     = azapi_resource.role_assignments["reader"].name == "11111111-1111-1111-1111-111111111111"
    error_message = "The AzAPI role assignment must use the utility module's retained UUID."
  }
}

run "private_endpoint_payload_preserves_legacy_identity" {
  command = plan

  assert {
    condition     = azapi_resource.private_endpoints["primary"].name == "pe-test"
    error_message = "The private endpoint must preserve an explicitly configured name."
  }

  assert {
    condition     = azapi_resource.private_endpoints["primary"].body.properties.customNetworkInterfaceName == "nic-test"
    error_message = "The private endpoint must preserve an explicitly configured NIC name."
  }

  assert {
    condition     = azapi_resource.private_endpoints["primary"].body.properties.privateLinkServiceConnections[0].name == "pse-test-aks"
    error_message = "The private endpoint must preserve the legacy default connection name."
  }

  assert {
    condition     = azapi_resource.private_endpoints["primary"].body.properties.applicationSecurityGroups[0].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/applicationSecurityGroups/asg-test"
    error_message = "The private endpoint payload must retain ASG associations."
  }

  assert {
    condition     = azapi_resource.private_dns_zone_groups["primary"].name == "default"
    error_message = "The private DNS zone group must preserve its configured name."
  }

  assert {
    condition     = azapi_resource.private_dns_zone_groups["primary"].body.properties.privateDnsZoneConfigs[0].name == "privatelink.eastus.azmk8s.io"
    error_message = "The DNS zone configuration name must match the legacy Azure-generated name."
  }
}

run "lock_notes_are_preserved" {
  command = plan

  assert {
    condition     = azapi_resource.lock[0].body.properties.notes == "Cannot delete the resource or its child resources."
    error_message = "The AzAPI lock must preserve the legacy default notes."
  }
}
