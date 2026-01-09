# Addon profiles configuration for the AKS cluster.
# When in automatic mode, the RP configures the recommended addons, so we must
# not enable them again here.
locals {
  addon_profiles = merge(
    var.log_analytics_workspace_id != null ? {
      omsagent = {
        enabled = true
        config = {
          logAnalyticsWorkspaceResourceID = var.log_analytics_workspace_id
          useAADAuth                      = var.oms_agent != null ? tostring(var.oms_agent.msi_auth_for_monitoring_enabled) : "false"
        }
      }
      } : {
      omsagent = {
        enabled = false
        config  = {}
      }
    },
    !local.is_automatic ? var.azure_policy_enabled ? {
      azurepolicy = { enabled = true }
      } : {
      azurepolicy = { enabled = false }
    } : null,
    var.ingress_application_gateway != null ? {
      ingressApplicationGateway = {
        enabled = true
        config = {
          applicationGatewayId   = var.ingress_application_gateway.application_gateway_id
          applicationGatewayName = var.ingress_application_gateway.application_gateway_name
          subnetCIDR             = var.ingress_application_gateway.subnet_cidr
          subnetId               = var.ingress_application_gateway.subnet_id
        }
      }
      } : {
      ingressApplicationGateway = {
        enabled = false
        config  = null
      }
    },
    !local.is_automatic ? var.key_vault_secrets_provider != null ? {
      azureKeyvaultSecretsProvider = {
        enabled = true
        config = {
          enableSecretRotation = var.key_vault_secrets_provider.secret_rotation_enabled
          rotationPollInterval = var.key_vault_secrets_provider.secret_rotation_interval
        }
      }
      } : {
      azureKeyvaultSecretsProvider = {
        enabled = false
        config  = null
      }
    } : null
  )
}
