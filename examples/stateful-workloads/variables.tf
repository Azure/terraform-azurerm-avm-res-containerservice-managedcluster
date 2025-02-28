variable "acr_task_content" {
  type        = string
  default     = <<-EOF
version: v1.1.0
steps:
  - cmd: bash echo Waiting 10 seconds the propagation of the Container Registry Data Importer and Data Reader role
  - cmd: bash sleep 10
  - cmd: az login --identity
  - cmd: az acr import --name $RegistryName --source docker.io/valkey/valkey:latest --image valkey:latest
EOF
  description = "The content of the ACR task"
}

variable "cluster_name" {
  type        = string
  default     = null
  description = "The name of the Kubernetes cluster"
}

variable "location" {
  type        = string
  default     = "centralus"
  description = "The location of the resource group. Leaving this as null will select a random region"
}

variable "mongodb_enabled" {
  type        = bool
  default     = false
  description = "Enable MongoDB"
}

variable "node_pools" {
  type = map(object({
    name       = string
    vm_size    = string
    node_count = number
    zones      = optional(list(string))
    os_type    = string
  }))
  default = {
    # This is an example of a node pool for a stateful workload with minimal configuration
    valkey = {
      name       = "valkey"
      vm_size    = "Standard_D2ds_v4"
      node_count = 3
      zones      = [1, 2, 3]
      os_type    = "Linux"
    }
  }
  description = "Optional. The additional node pools for the Kubernetes cluster."
}

variable "resource_group_name" {
  type        = string
  default     = null
  description = "The name of the resource group"
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
