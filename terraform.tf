terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.12, < 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "< 4.0.0"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
