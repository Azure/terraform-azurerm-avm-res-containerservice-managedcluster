variable "name" {
  type        = string
  description = <<DESCRIPTION
The name of the resource.
DESCRIPTION
}

variable "parent_id" {
  type        = string
  description = <<DESCRIPTION
The parent resource ID for this resource.
DESCRIPTION
}

variable "maintenance_window" {
  type = object({
    duration_hours = number
    not_allowed_dates = optional(list(object({
      end   = string
      start = string
    })))
    schedule = object({
      absolute_monthly = optional(object({
        day_of_month    = number
        interval_months = number
      }))
      daily = optional(object({
        interval_days = number
      }))
      relative_monthly = optional(object({
        day_of_week     = string
        interval_months = number
        week_index      = string
      }))
      weekly = optional(object({
        day_of_week    = string
        interval_weeks = number
      }))
    })
    start_date = optional(string)
    start_time = string
    utc_offset = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Maintenance window used to configure scheduled auto-upgrade for a Managed Cluster.

- `duration_hours` - Length of maintenance window range from 4 to 24 hours.
- `not_allowed_dates` - Date ranges on which upgrade is not allowed. 'utcOffset' applies to this field. For example, with 'utcOffset: +02:00' and 'dateSpan' being '2022-12-23' to '2023-01-03', maintenance will be blocked from '2022-12-22 22:00' to '2023-01-03 22:00' in UTC time.
- `schedule` - One and only one of the schedule types should be specified. Choose either 'daily', 'weekly', 'absoluteMonthly' or 'relativeMonthly' for your maintenance schedule.
  - `absolute_monthly` - For schedules like: 'recur every month on the 15th' or 'recur every 3 months on the 20th'.
    - `day_of_month` - The date of the month.
    - `interval_months` - Specifies the number of months between each set of occurrences.
  - `daily` - For schedules like: 'recur every day' or 'recur every 3 days'.
    - `interval_days` - Specifies the number of days between each set of occurrences.
  - `relative_monthly` - For schedules like: 'recur every month on the first Monday' or 'recur every 3 months on last Friday'.
    - `day_of_week` - The weekday enum.
    - `interval_months` - Specifies the number of months between each set of occurrences.
    - `week_index` - The week index. Specifies on which week of the month the dayOfWeek applies.
  - `weekly` - For schedules like: 'recur every Monday' or 'recur every 3 weeks on Wednesday'.
    - `day_of_week` - The weekday enum.
    - `interval_weeks` - Specifies the number of weeks between each set of occurrences.
- `start_date` - The date the maintenance window activates. If the current date is before this date, the maintenance window is inactive and will not be used for upgrades. If not specified, the maintenance window will be active right away.
- `start_time` - The start time of the maintenance window. Accepted values are from '00:00' to '23:59'. 'utcOffset' applies to this field. For example: '02:00' with 'utcOffset: +02:00' means UTC time '00:00'.
- `utc_offset` - The UTC offset in format +/-HH:mm. For example, '+05:30' for IST and '-07:00' for PST. If not specified, the default is '+00:00'.

DESCRIPTION

  validation {
    condition     = var.maintenance_window == null || var.maintenance_window.duration_hours >= 4
    error_message = "maintenance_window.duration_hours must be greater than or equal to 4."
  }
  validation {
    condition     = var.maintenance_window == null || var.maintenance_window.duration_hours <= 24
    error_message = "maintenance_window.duration_hours must be less than or equal to 24."
  }
  validation {
    condition     = var.maintenance_window == null || can(regex("^\\d{2}:\\d{2}$", var.maintenance_window.start_time))
    error_message = "maintenance_window.start_time must match the pattern: ^\\d{2}:\\d{2}$."
  }
  validation {
    condition     = var.maintenance_window == null || var.maintenance_window.utc_offset == null || can(regex("^(-|\\+)[0-9]{2}:[0-9]{2}$", var.maintenance_window.utc_offset))
    error_message = "maintenance_window.utc_offset must match the pattern: ^(-|\\+)[0-9]{2}:[0-9]{2}$."
  }
}

variable "not_allowed_time" {
  type = list(object({
    end   = optional(string)
    start = optional(string)
  }))
  default     = null
  description = <<DESCRIPTION
Time slots on which upgrade is not allowed.
DESCRIPTION
}

variable "time_in_week" {
  type = list(object({
    day        = optional(string)
    hour_slots = optional(list(number))
  }))
  default     = null
  description = <<DESCRIPTION
Time slots during the week when planned maintenance is allowed to proceed. If two array entries specify the same day of the week, the applied configuration is the union of times in both entries.
DESCRIPTION
}
