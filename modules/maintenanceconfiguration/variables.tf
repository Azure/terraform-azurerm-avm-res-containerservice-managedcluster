variable "cluster_resource_id" {
  type        = string
  description = "Resource ID of the parent managed cluster."
}

variable "duration_hours" {
  type        = number
  description = "Duration of the maintenance window in hours."
}

variable "frequency" {
  type        = string
  description = "Maintenance window frequency: Daily, Weekly, AbsoluteMonthly, RelativeMonthly."
}

variable "interval" {
  type        = number
  description = "Interval associated with the frequency (days, weeks or months depending on frequency)."
}

variable "day_of_month" {
  type        = number
  default     = null
  description = "Day of month (AbsoluteMonthly)."
}

variable "day_of_week" {
  type        = string
  default     = null
  description = "Day of week (Weekly or RelativeMonthly)."
}

variable "enable" {
  type        = bool
  default     = true
  description = "Whether to create the maintenance configuration resource."
}

variable "enable_telemetry" {
  type        = bool
  default     = false
  description = "Whether telemetry headers should be added."
}

variable "not_allowed_end" {
  type        = string
  default     = null
  description = "End date for a single not-allowed date range (YYYY-MM-DD)."
}

variable "not_allowed_start" {
  type        = string
  default     = null
  description = "Start date for a single not-allowed date range (YYYY-MM-DD)."
}

variable "start_date" {
  type        = string
  default     = null
  description = "Optional ISO8601 start date (YYYY-MM-DD)."
}

variable "start_time" {
  type        = string
  default     = "00:00"
  description = "Start time (HH:MM)."
}

variable "user_agent_header" {
  type        = string
  default     = null
  description = "User-Agent header value when telemetry is enabled."
}

variable "utc_offset" {
  type        = string
  default     = "+00:00"
  description = "UTC offset (+/-HH:MM)."
}

variable "week_index" {
  type        = string
  default     = null
  description = "Week index within month (e.g. First, Second, Third, Fourth, Last) for RelativeMonthly."
}
