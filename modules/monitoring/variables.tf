variable "aks_cluster_id" {
  type        = string
  description = "The resource ID of the AKS cluster"
  nullable    = false
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be created"
  nullable    = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The resource ID of the Log Analytics workspace"
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = "The resource ID of the parent resource group"
  nullable    = false
}

variable "prometheus_workspace_id" {
  type        = string
  description = "The resource ID of the Azure Monitor workspace for managed Prometheus"
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
