mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location  = "eastus"
  name      = "test-aks"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
}

run "dns_prefix_auto_generated_when_neither_set" {
  command = plan

  assert {
    condition     = azapi_resource.this.body.properties.dnsPrefix != null
    error_message = "dnsPrefix should be auto-generated when neither dns_prefix nor fqdn_subdomain is set."
  }
}

run "fqdn_subdomain_excludes_dns_prefix" {
  command = plan

  variables {
    fqdn_subdomain = "mycluster"
  }

  assert {
    condition     = azapi_resource.this.body.properties.fqdnSubdomain == "mycluster"
    error_message = "fqdnSubdomain should be set to the provided value."
  }

  assert {
    condition     = !can(azapi_resource.this.body.properties.dnsPrefix)
    error_message = "dnsPrefix must not be present when fqdn_subdomain is set."
  }
}

run "explicit_dns_prefix_used_when_set" {
  command = plan

  variables {
    dns_prefix = "myprefix"
  }

  assert {
    condition     = azapi_resource.this.body.properties.dnsPrefix == "myprefix"
    error_message = "dnsPrefix should use the explicitly provided value."
  }
}
