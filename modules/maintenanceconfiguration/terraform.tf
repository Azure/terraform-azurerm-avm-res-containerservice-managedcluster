terraform {
  required_version = ">= 1.11, < 2.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.9"
    }
  }
}
