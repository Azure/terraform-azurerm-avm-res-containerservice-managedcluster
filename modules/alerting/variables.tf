variable "aks_cluster_id" {
  type        = string
  description = "The resource ID of the AKS cluster"
  nullable    = false
}

variable "alert_email" {
  type        = string
  description = "Email address for alert notifications"
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = "The parent resource group ID"
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
