locals {
  sensitive_body = var.windows_profile == null ? null : {
    properties = {
      windowsProfile = {
        adminPassword = var.windows_profile_password
      }
    }
  }
}
