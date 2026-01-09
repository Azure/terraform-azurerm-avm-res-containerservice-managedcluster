output "action_group_id" {
  description = "The resource ID of the action group"
  value       = azapi_resource.ag.id
}

output "cpu_alert_id" {
  description = "The resource ID of the CPU usage alert"
  value       = azapi_resource.metricalert_cpu.id
}

output "memory_alert_id" {
  description = "The resource ID of the memory usage alert"
  value       = azapi_resource.metricalert_memory.id
}

output "resource_id" {
  description = "The resource ID of the action group created by this module"
  value       = azapi_resource.ag.id
}
