# Addon profiles configuration for the AKS cluster.
# When in automatic mode, the RP configures the recommended addons, so we must
# not enable them again here.
locals {
  addon_profiles = merge(
    var.addon_profile_oms_agent != null ? {
      omsagent = {
        enabled = var.addon_profile_oms_agent.enabled
        config = tomap({
          logAnalyticsWorkspaceResourceID = var.addon_profile_oms_agent.config.log_analytics_workspace_resource_id
          useAADAuth                      = tostring(var.addon_profile_oms_agent.config.use_aad_auth)
        })
        identity = null
      }
      } : {
      omsagent = {
        enabled  = false
        config   = {}
        identity = null
      }
    },
    !local.is_automatic ? {
      azurepolicy = {
        enabled  = var.addon_profile_azure_policy.enabled
        config   = null
        identity = null
      }
    } : null,
    var.addon_profile_ingress_application_gateway != null ? {
      ingressApplicationGateway = {
        enabled = var.addon_profile_ingress_application_gateway.enabled
        config = tomap({
          applicationGatewayId   = var.addon_profile_ingress_application_gateway.config.application_gateway_id
          applicationGatewayName = var.addon_profile_ingress_application_gateway.config.application_gateway_name
          subnetCIDR             = var.addon_profile_ingress_application_gateway.config.subnet_cidr
          subnetId               = var.addon_profile_ingress_application_gateway.config.subnet_id
        })
        identity = null
      }
      } : {
      ingressApplicationGateway = {
        enabled  = false
        config   = null
        identity = null
      }
    },
    !local.is_automatic ? var.addon_profile_key_vault_secrets_provider != null ? {
      azureKeyvaultSecretsProvider = {
        enabled = true
        config = tomap({
          enableSecretRotation = var.addon_profile_key_vault_secrets_provider.secret_rotation_enabled
          rotationPollInterval = var.addon_profile_key_vault_secrets_provider.secret_rotation_interval
        })
        identity = null
      }
      } : {
      azureKeyvaultSecretsProvider = {
        enabled  = false
        config   = null
        identity = null
      }
    } : null,
    var.addon_profile_confidential_computing != null ? {
      confidentialComputing = {
        enabled  = var.addon_profile_confidential_computing.enabled
        config   = null
        identity = null
      }
      } : {
      confidentialComputing = {
        enabled  = false
        config   = null
        identity = null
      }
    },
    {
      for profile, data in var.addon_profiles_extra : profile => {
        enabled  = data.enabled
        config   = data.config
        identity = data.identity
    } },
  )
}
