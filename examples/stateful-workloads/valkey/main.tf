
resource "azurerm_key_vault_secret" "valkey_password_file" {
  key_vault_id = var.key_vault_id
  name         = "valkey-password-file"
  value        = <<EOF
requirepass  ${coalesce(var.valkey_password, random_password.requirepass.result)}
primaryauth  ${coalesce(var.valkey_password, random_password.primaryauth.result)}
EOF
}


resource "random_password" "requirepass" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}

resource "random_password" "primaryauth" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}
