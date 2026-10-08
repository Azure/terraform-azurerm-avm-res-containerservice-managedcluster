# AKS requires an identity or service principal to manage its dependent resources.
# Preserve this module's existing system-assigned identity default rather than
# changing consumer behavior to satisfy the generic empty-default interface.
rule "avm_interface_managed_identities" {
  enabled = false
}
