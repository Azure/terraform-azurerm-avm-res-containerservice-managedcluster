variable "acr_registry_name" {
  type        = string
  default     = null
  description = "The name of the Azure Container Registry"
}

variable "acr_task_content" {
  type        = string
  default     = <<-EOF
version: v1.1.0
steps:
  - cmd: bash echo Waiting 60 seconds the propagation of the Container Registry Data Importer and Data Reader role
  - cmd: bash sleep 60
  - cmd: az login --identity
  - cmd: az acr import --name $RegistryName --source acrforavmexamples.azurecr.io/valkey:latest --image valkey:latest
EOF
  description = "The content of the ACR task"
}

variable "agent_pools" {
  type = map(object({
    name               = string
    vm_size            = string
    count_of           = number
    availability_zones = optional(list(string))
    os_type            = string
    upgrade_settings = optional(object({
      drain_timeout_in_minutes      = optional(number)
      node_soak_duration_in_minutes = optional(number)
      max_surge                     = string
    }))
  }))
  default = {
    # This is an example of a node pool for a stateful workload with minimal configuration
    valkey = {
      name     = "valkey"
      vm_size  = "Standard_D2ds_v4"
      count_of = 3
      # Provide zones as strings (variable type list(string))
      availability_zones = ["1", "2", "3"]
      os_type            = "Linux"
      upgrade_settings = {
        max_surge = "10%"
      }
    }
  }
  description = "Optional. The additional agent pools for the Kubernetes cluster."
}

variable "aks_mongodb_backup_storage_account_name" {
  type        = string
  default     = null
  description = "The name of the backup storage account"
}

variable "cluster_name" {
  type        = string
  default     = null
  description = "The name of the Kubernetes cluster"
}

variable "identity_name" {
  type        = string
  default     = null
  description = "The name of the user assigner identity"
}

variable "keyvault_name" {
  type        = string
  default     = null
  description = "The name of the Azure Key Vault"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "The location of the resource group. Leaving this as null will select a random region"
}

variable "mongodb_enabled" {
  type        = bool
  default     = false
  description = "Enable MongoDB"
}

variable "mongodb_kv_secrets" {
  type        = map(string)
  default     = null
  description = "Map of secret names to their values"
}

variable "mongodb_namespace" {
  type        = string
  default     = null
  description = "The name of the mongodb namespace to create"
}

variable "resource_group_name" {
  type        = string
  default     = null
  description = "The name of the resource group"
}

variable "service_account_name" {
  type        = string
  default     = null
  description = "The name of the service account to create"
}

variable "valkey_enabled" {
  type        = bool
  default     = false
  description = "Enable Valkey"
}

variable "valkey_password" {
  type        = string
  default     = "" #generate password using openssl rand -base64 32
  description = "The password for the Valkey"
}
