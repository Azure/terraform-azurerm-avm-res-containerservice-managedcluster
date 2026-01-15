terraform {
  required_version = "~> 1.12"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.7"
    }
  }
}
