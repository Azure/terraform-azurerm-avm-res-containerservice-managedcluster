variable "alert_email" {
  type        = string
  default     = null
  description = "The email address to send alerts to."
}

variable "onboard_alerts" {
  type        = bool
  default     = false
  description = "Whether to enable recommended alerts. Set to false to disable alerts even if monitoring is enabled and alert_email is provided."
  nullable    = false

  validation {
    condition     = !var.onboard_alerts || var.alert_email != null
    error_message = "When `onboard_alerts` is true, `alert_email` must be provided."
  }
}

variable "onboard_monitoring" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
Whether to enable monitoring resources. Set to false to disable monitoring even if workspace IDs are provided.
DESCRIPTION

  validation {
    condition     = !var.onboard_monitoring || try(var.addon_profile_oms_agent.config.log_analytics_workspace_resource_id, null) != null
    error_message = "When `onboard_monitoring` is true, enable oms addon and provide `log_analytics_workspace_resource_id`."
  }
}

variable "prometheus_workspace_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
The monitor workspace resource ID for managed Prometheus.

Make sure to to also specify `var.azure_monitor_profile`,
Ensure that `kube_state_metrics` are configured.
DESCRIPTION
}
