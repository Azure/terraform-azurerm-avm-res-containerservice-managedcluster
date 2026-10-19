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
    condition     = azapi_resource.this.type == "Microsoft.ContainerService/managedClusters@2026-03-02-preview"
    error_message = "ALB and App Routing Gateway API require a preview API supporting both settings."
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

run "disabled_alb_preserves_gateway_api_implementation" {
  command = apply

  variables {
    ingress_profile = {
      application_load_balancer = {
        enabled = false
      }
      gateway_api = {
        installation = "Standard"
      }
      web_app_routing = {
        enabled = false
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
    condition     = azapi_resource.this.type == "Microsoft.ContainerService/managedClusters@2026-03-02-preview"
    error_message = "An explicit disabled ALB must not select the obsolete API lacking App Routing Gateway API."
  }

  assert {
    condition     = azapi_resource.this.body.properties.ingressProfile.applicationLoadBalancer.enabled == false && azapi_resource.this.body.properties.ingressProfile.webAppRouting.gatewayAPIImplementations.appRoutingIstio.mode == "Enabled"
    error_message = "Disabled ALB and enabled App Routing Gateway API must both be retained."
  }
}

run "enabled_alb_gateway_api_and_kube_proxy_use_compatible_api" {
  command = apply

  variables {
    ingress_profile = {
      application_load_balancer = {
        enabled = true
      }
      gateway_api = {
        installation = "Standard"
      }
      web_app_routing = {
        gateway_api_implementations = {
          app_routing_istio = {
            mode = "Enabled"
          }
        }
      }
    }
    kube_proxy_config = {
      enabled = true
      mode    = "IPTABLES"
    }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.ContainerService/managedClusters@2026-03-02-preview"
    error_message = "ALB must not override the API required by kube-proxy and App Routing Gateway API."
  }

  assert {
    condition     = azapi_resource.this.body.properties.ingressProfile.applicationLoadBalancer.enabled == true && azapi_resource.this.body.properties.ingressProfile.webAppRouting.gatewayAPIImplementations.appRoutingIstio.mode == "Enabled" && azapi_resource.this.body.properties.networkProfile.kubeProxyConfig.mode == "IPTABLES"
    error_message = "ALB, App Routing Gateway API, and kube-proxy must all be serialized together."
  }
}

run "disabled_alb_gateway_api_and_kube_proxy_use_compatible_api" {
  command = apply

  variables {
    ingress_profile = {
      application_load_balancer = {
        enabled = false
      }
      gateway_api = {
        installation = "Standard"
      }
      web_app_routing = {
        gateway_api_implementations = {
          app_routing_istio = {
            mode = "Enabled"
          }
        }
      }
    }
    kube_proxy_config = {
      enabled = true
      mode    = "IPVS"
    }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.ContainerService/managedClusters@2026-03-02-preview"
    error_message = "Disabled ALB must not override the API required by kube-proxy and App Routing Gateway API."
  }

  assert {
    condition     = azapi_resource.this.body.properties.ingressProfile.applicationLoadBalancer.enabled == false && azapi_resource.this.body.properties.ingressProfile.webAppRouting.gatewayAPIImplementations.appRoutingIstio.mode == "Enabled" && azapi_resource.this.body.properties.networkProfile.kubeProxyConfig.mode == "IPVS"
    error_message = "An explicit disabled ALB must preserve both App Routing Gateway API and kube-proxy settings."
  }
}

run "alb_without_gateway_implementation_uses_supported_preview" {
  command = apply

  variables {
    ingress_profile = {
      application_load_balancer = {
        enabled = true
      }
    }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.ContainerService/managedClusters@2026-03-02-preview" && azapi_resource.this.body.properties.ingressProfile.applicationLoadBalancer.enabled == true
    error_message = "The existing ALB-only configuration should remain supported."
  }
}

run "omitted_preview_features_preserve_default_api" {
  command = apply

  assert {
    condition     = azapi_resource.this.type == "Microsoft.ContainerService/managedClusters@2026-03-01"
    error_message = "Omitting ALB and kube-proxy configuration must preserve the stable default API."
  }
}

run "omitted_preview_features_preserve_custom_api" {
  command = apply

  variables {
    resource_types = {
      containerservice_managed_clusters = "Microsoft.ContainerService/managedClusters@2026-05-02-preview"
    }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.ContainerService/managedClusters@2026-05-02-preview"
    error_message = "Omitting ALB and kube-proxy configuration must preserve the caller's API override."
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
