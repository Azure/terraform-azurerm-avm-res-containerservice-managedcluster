variable "aks_cluster_id" {
  type        = string
  description = "The resource ID of the AKS cluster"
  nullable    = false
}

variable "aks_cluster_name" {
  type        = string
  description = "The name of the AKS cluster"
  nullable    = false
}

variable "alert_email" {
  type        = string
  description = "Email address for alert notifications"
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
  nullable    = false
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID"
  nullable    = false
}
