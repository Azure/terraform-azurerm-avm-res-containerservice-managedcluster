moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}

moved {
  from = azurerm_monitor_diagnostic_setting.this
  to   = azapi_resource.diagnostic_settings
}
