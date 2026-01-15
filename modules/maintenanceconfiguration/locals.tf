locals {
  resource_body = {
    properties = {
      maintenanceWindow = var.maintenance_window == null ? null : {
        durationHours = var.maintenance_window.duration_hours
        notAllowedDates = var.maintenance_window.not_allowed_dates == null ? null : [for item in var.maintenance_window.not_allowed_dates : item == null ? null : {
          end   = item.end
          start = item.start
        }]
        schedule = var.maintenance_window.schedule == null ? null : {
          absoluteMonthly = var.maintenance_window.schedule.absolute_monthly == null ? null : {
            dayOfMonth     = var.maintenance_window.schedule.absolute_monthly.day_of_month
            intervalMonths = var.maintenance_window.schedule.absolute_monthly.interval_months
          }
          daily = var.maintenance_window.schedule.daily == null ? null : {
            intervalDays = var.maintenance_window.schedule.daily.interval_days
          }
          relativeMonthly = var.maintenance_window.schedule.relative_monthly == null ? null : {
            dayOfWeek      = var.maintenance_window.schedule.relative_monthly.day_of_week
            intervalMonths = var.maintenance_window.schedule.relative_monthly.interval_months
            weekIndex      = var.maintenance_window.schedule.relative_monthly.week_index
          }
          weekly = var.maintenance_window.schedule.weekly == null ? null : {
            dayOfWeek     = var.maintenance_window.schedule.weekly.day_of_week
            intervalWeeks = var.maintenance_window.schedule.weekly.interval_weeks
          }
        }
        startDate = var.maintenance_window.start_date
        startTime = var.maintenance_window.start_time
        utcOffset = var.maintenance_window.utc_offset
      }
      notAllowedTime = var.not_allowed_time == null ? null : [for item in var.not_allowed_time : item == null ? null : {
        end   = item.end
        start = item.start
      }]
      timeInWeek = var.time_in_week == null ? null : [for item in var.time_in_week : item == null ? null : {
        day       = item.day
        hourSlots = item.hour_slots == null ? null : [for item in item.hour_slots : item]
      }]
    }
  }
}
