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

variable "monitor_workspace_id" {
  type        = string
  description = "The resource ID of the Azure Monitor workspace"
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
