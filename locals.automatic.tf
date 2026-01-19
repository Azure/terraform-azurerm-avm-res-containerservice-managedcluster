locals {
  is_automatic = var.sku != null && var.sku.name == "Automatic"
}
