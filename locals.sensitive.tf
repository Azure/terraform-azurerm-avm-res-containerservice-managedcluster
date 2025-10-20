locals {
  sensitive_body = {
    properties = {
      windowsProfile = var.windows_profile != null ? {
        adminPassword = var.windows_profile_password
      } : null
    }
  }
}
