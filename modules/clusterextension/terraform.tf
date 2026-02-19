terraform {
  required_version = "~> 1.12"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
  }
}
