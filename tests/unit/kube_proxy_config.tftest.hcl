mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location  = "eastus"
  name      = "test-aks"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  network_profile = {
    network_plugin = "none"
  }
}

run "kube_proxy_config_omitted_when_null" {
  command = plan

  assert {
    condition     = !can(azapi_resource.this.body.properties.networkProfile.kubeProxyConfig)
    error_message = "networkProfile.kubeProxyConfig must be omitted from the payload when kube_proxy_config is null."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.ContainerService/managedClusters@2026-03-01"
    error_message = "The stable managed cluster API should remain the default when kube_proxy_config is null."
  }
}

run "disabled_kube_proxy_config_is_serialized" {
  command = plan

  variables {
    kube_proxy_config = {
      enabled = false
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.kubeProxyConfig.enabled == false
    error_message = "networkProfile.kubeProxyConfig.enabled should serialize false for BYO CNI."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.ContainerService/managedClusters@2026-03-02-preview"
    error_message = "Setting kube_proxy_config should opt the managed cluster into an API version that supports the preview property."
  }
}

run "ipvs_kube_proxy_config_is_serialized" {
  command = plan

  variables {
    kube_proxy_config = {
      enabled = true
      mode    = "IPVS"
      ipvs_config = {
        scheduler               = "LeastConnection"
        tcp_fin_timeout_seconds = 120
        tcp_timeout_seconds     = 900
        udp_timeout_seconds     = 300
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.kubeProxyConfig.mode == "IPVS"
    error_message = "networkProfile.kubeProxyConfig.mode should serialize the configured proxy mode."
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.kubeProxyConfig.ipvsConfig.scheduler == "LeastConnection"
    error_message = "networkProfile.kubeProxyConfig.ipvsConfig.scheduler should serialize the configured scheduler."
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkProfile.kubeProxyConfig.ipvsConfig.tcpFinTimeoutSeconds == 120
    error_message = "networkProfile.kubeProxyConfig.ipvsConfig should serialize timeout values using ARM property names."
  }
}

run "invalid_kube_proxy_mode_is_rejected" {
  command = plan

  variables {
    kube_proxy_config = {
      enabled = true
      mode    = "INVALID"
    }
  }

  expect_failures = [
    var.kube_proxy_config,
  ]
}

run "invalid_ipvs_scheduler_is_rejected" {
  command = plan

  variables {
    kube_proxy_config = {
      enabled = true
      mode    = "IPVS"
      ipvs_config = {
        scheduler = "INVALID"
      }
    }
  }

  expect_failures = [
    var.kube_proxy_config,
  ]
}

run "ipvs_config_requires_ipvs_mode" {
  command = plan

  variables {
    kube_proxy_config = {
      enabled = true
      mode    = "IPTABLES"
      ipvs_config = {
        scheduler = "RoundRobin"
      }
    }
  }

  expect_failures = [
    var.kube_proxy_config,
  ]
}

run "non_positive_ipvs_timeout_is_rejected" {
  command = plan

  variables {
    kube_proxy_config = {
      enabled = true
      mode    = "IPVS"
      ipvs_config = {
        tcp_timeout_seconds = 0
      }
    }
  }

  expect_failures = [
    var.kube_proxy_config,
  ]
}

run "disabling_kube_proxy_requires_byo_cni" {
  command = plan

  variables {
    kube_proxy_config = {
      enabled = false
    }
    network_profile = {
      network_plugin = "azure"
    }
  }

  expect_failures = [
    var.kube_proxy_config,
  ]
}

run "automatic_cluster_rejects_kube_proxy_config" {
  command = plan

  variables {
    kube_proxy_config = {
      enabled = true
    }
    sku = {
      name = "Automatic"
      tier = "Standard"
    }
  }

  expect_failures = [
    var.kube_proxy_config,
  ]
}
