variable "kv_secrets" {
  description = "Map of secret names to their values"
  type        = map(string)
  default     = null
}
variable "key_vault_id" {
  type        = string
  description = "The resource ID of the key vault"

}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

variable "location" {
  type        = string
  description = "The location of the storage account"
}

variable "principal_id" {
  type        = string
  description = "The principal ID of the user"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"

}
