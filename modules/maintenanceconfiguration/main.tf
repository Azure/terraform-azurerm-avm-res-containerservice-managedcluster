#############################################
# AKS Maintenance Configuration (Auto Upgrade)
#############################################

locals {
  not_allowed_dates = (var.not_allowed_start != null && var.not_allowed_end != null) ? [{
    start = var.not_allowed_start
    end   = var.not_allowed_end
  }] : null
  # Filter null schedule types; only one should remain.
  schedule = { for k, v in local.schedule_map : k => v if v != null }
  schedule_map = {
    daily = var.frequency == "Daily" ? {
      intervalDays = tonumber(var.interval)
    } : null
    weekly = var.frequency == "Weekly" ? {
      dayOfWeek     = var.day_of_week
      intervalWeeks = tonumber(var.interval)
    } : null
    absoluteMonthly = var.frequency == "AbsoluteMonthly" ? {
      dayOfMonth     = var.day_of_month
      intervalMonths = tonumber(var.interval)
    } : null
    relativeMonthly = var.frequency == "RelativeMonthly" ? {
      dayOfWeek      = var.day_of_week
      intervalMonths = tonumber(var.interval)
      weekIndex      = var.week_index
    } : null
  }
}

resource "azapi_resource" "this" {
  count = var.enable ? 1 : 0

  name      = "aksManagedAutoUpgradeSchedule"
  parent_id = var.parent_id
  type      = "Microsoft.ContainerService/managedClusters/maintenanceConfigurations@2025-07-01"
  body = {
    properties = {
      maintenanceWindow = {
        durationHours   = tonumber(var.duration_hours)
        startTime       = var.start_time
        utcOffset       = var.utc_offset
        startDate       = var.start_date
        schedule        = local.schedule
        notAllowedDates = local.not_allowed_dates
      }
    }
  }
  create_headers            = var.enable_telemetry && var.user_agent_header != null ? { "User-Agent" = var.user_agent_header } : null
  delete_headers            = var.enable_telemetry && var.user_agent_header != null ? { "User-Agent" = var.user_agent_header } : null
  ignore_null_property      = true
  read_headers              = var.enable_telemetry && var.user_agent_header != null ? { "User-Agent" = var.user_agent_header } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry && var.user_agent_header != null ? { "User-Agent" = var.user_agent_header } : null

  lifecycle {
    precondition {
      condition     = contains(["Daily", "Weekly", "AbsoluteMonthly", "RelativeMonthly"], var.frequency)
      error_message = "frequency must be one of Daily, Weekly, AbsoluteMonthly, RelativeMonthly"
    }
    precondition {
      condition     = var.frequency != "Weekly" || (var.day_of_week != null)
      error_message = "day_of_week must be provided for Weekly frequency"
    }
    precondition {
      condition     = var.frequency != "AbsoluteMonthly" || (var.day_of_month != null)
      error_message = "day_of_month must be provided for AbsoluteMonthly frequency"
    }
    precondition {
      condition     = var.frequency != "RelativeMonthly" || (var.day_of_week != null && var.week_index != null)
      error_message = "day_of_week and week_index must be provided for RelativeMonthly frequency"
    }
  }
}
