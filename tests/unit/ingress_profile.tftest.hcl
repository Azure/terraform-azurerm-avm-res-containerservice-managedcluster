mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location  = "eastus"
  name      = "test-aks"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
}

run "gateway_api_fields_are_passed_through" {
  command = plan

  variables {
    ingress_profile = {
      application_load_balancer = {
        enabled = true
      }
      gateway_api = {
        installation = "Standard"
      }
      web_app_routing = {
        enabled = true
        gateway_api_implementations = {
          app_routing_istio = {
            mode = "Enabled"
          }
        }
        nginx = {
          default_ingress_controller_type = "None"
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.ingressProfile.applicationLoadBalancer.enabled == true
    error_message = "Ingress profile should pass through the Application Gateway for Containers ALB Controller setting."
  }

  assert {
    condition     = azapi_resource.this.body.properties.ingressProfile.gatewayAPI.installation == "Standard"
    error_message = "Ingress profile should pass through the managed Gateway API installation setting."
  }

  assert {
    condition     = azapi_resource.this.body.properties.ingressProfile.webAppRouting.gatewayAPIImplementations.appRoutingIstio.mode == "Enabled"
    error_message = "Ingress profile should pass through the App Routing Istio Gateway API implementation setting."
  }

  assert {
    condition     = azapi_resource.this.body.properties.ingressProfile.webAppRouting.nginx.defaultIngressControllerType == "None"
    error_message = "Ingress profile should preserve the existing nginx setting when Gateway API fields are configured."
  }
}

run "optional_gateway_api_fields_can_be_omitted" {
  command = plan

  variables {
    ingress_profile = {
      gateway_api = {}
      web_app_routing = {
        gateway_api_implementations = {
          app_routing_istio = {}
        }
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.ingressProfile.gatewayAPI.installation == null
    error_message = "The managed Gateway API installation should remain unset when omitted."
  }

  assert {
    condition     = azapi_resource.this.body.properties.ingressProfile.webAppRouting.gatewayAPIImplementations.appRoutingIstio.mode == null
    error_message = "The App Routing Istio mode should remain unset when omitted."
  }
}
