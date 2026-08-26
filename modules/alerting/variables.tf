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

variable "ignore_body_changes" {
  type = object({
    insights_action_groups = optional(list(string), [])
    insights_metric_alerts = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths to ignore for each AzAPI resource, in dot notation. Changes take
effect only after apply, and ignored configuration is not sent to Azure until the
path is removed.

- `insights_action_groups` - Paths ignored on the action group.
- `insights_metric_alerts` - Paths ignored on the metric alerts.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    insights_action_groups = optional(string, "Microsoft.Insights/actionGroups@2024-10-01-preview")
    insights_metric_alerts = optional(string, "Microsoft.Insights/metricAlerts@2018-03-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by this module.

- `insights_action_groups` - Resource type and API version for the action group.
- `insights_metric_alerts` - Resource type and API version for the metric alerts.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to the AzAPI resources in this module.

- `error_message_regex` - Regular expressions matching error messages that should be retried.
- `interval_seconds` - Initial delay between retries, in seconds.
- `max_interval_seconds` - Maximum delay between retries, in seconds.
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Timeouts applied to the AzAPI resources in this module.

- `create` - Timeout for create operations.
- `read` - Timeout for read operations.
- `update` - Timeout for update operations.
- `delete` - Timeout for delete operations.
DESCRIPTION
}
