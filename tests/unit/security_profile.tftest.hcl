mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location  = "eastus"
  name      = "test-aks"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
}

run "image_integrity_is_serialized" {
  command = plan

  variables {
    addon_profile_azure_policy = {
      enabled = true
    }
    oidc_issuer_profile = {
      enabled = true
    }
    security_profile = {
      image_integrity = {
        enabled = true
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.securityProfile.imageIntegrity.enabled == true
    error_message = "securityProfile.imageIntegrity.enabled should be passed through to the managed cluster."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.ContainerService/managedClusters@2026-03-02-preview"
    error_message = "Image Integrity should select a preview API version that supports securityProfile.imageIntegrity."
  }
}

run "disabled_image_integrity_is_serialized" {
  command = plan

  variables {
    security_profile = {
      image_integrity = {
        enabled = false
      }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.securityProfile.imageIntegrity.enabled == false
    error_message = "securityProfile.imageIntegrity.enabled should serialize false when explicitly disabled."
  }
}

run "image_integrity_requires_azure_policy" {
  command = plan

  variables {
    oidc_issuer_profile = {
      enabled = true
    }
    security_profile = {
      image_integrity = {
        enabled = true
      }
    }
  }

  expect_failures = [
    var.security_profile,
  ]
}

run "image_integrity_requires_oidc_issuer" {
  command = plan

  variables {
    addon_profile_azure_policy = {
      enabled = true
    }
    security_profile = {
      image_integrity = {
        enabled = true
      }
    }
  }

  expect_failures = [
    var.security_profile,
  ]
}

run "image_integrity_rejects_automatic_clusters" {
  command = plan

  variables {
    addon_profile_azure_policy = {
      enabled = true
    }
    oidc_issuer_profile = {
      enabled = true
    }
    security_profile = {
      image_integrity = {
        enabled = true
      }
    }
    sku = {
      name = "Automatic"
      tier = "Standard"
    }
  }

  expect_failures = [
    var.security_profile,
  ]
}
