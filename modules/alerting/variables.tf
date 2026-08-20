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

variable "resource_types" {
  type = object({
    insights_action_groups = optional(string, "Microsoft.Insights/actionGroups@2024-10-01-preview")
    insights_metric_alerts = optional(string, "Microsoft.Insights/metricAlerts@2018-03-01")
  })
  default     = {}
  description = "AzAPI resource type overrides for action groups and metric alerts."
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Retry configuration applied to every supported AzAPI resource declared by this module."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Default per-operation timeouts applied to every supported AzAPI resource declared by this module."
}

variable "ignore_body_changes" {
  type = object({
    insights_action_groups = optional(list(string), [])
    insights_metric_alerts = optional(list(string), [])
  })
  default     = {}
  description = "Body-relative dot-notation paths to ignore for each AzAPI resource. Changes take effect only after an apply."
  nullable    = false
}
