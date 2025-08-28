# Azure Kubernetes Service Migration to azapi_resource
# This file contains the migrated core properties configuration

resource "azapi_resource" "aks_cluster" {
  type      = "Microsoft.ContainerService/managedClusters@2024-09-01"
  parent_id = data.azurerm_resource_group.this.id
  name      = "${var.name}${var.cluster_suffix}"
  location  = var.location

  body = {
    properties = {
      # Core Properties Migration - Selected Arguments Only
      kubernetesVersion               = var.kubernetes_version
      dnsPrefix                       = var.dns_prefix
      fqdnSubdomain                   = var.dns_prefix_private_cluster
      diskEncryptionSetID             = var.disk_encryption_set_id
      enableRBAC                      = var.role_based_access_control_enabled
      disableLocalAccounts            = var.local_account_disabled

      # Auto Upgrade Profile
      autoUpgradeProfile = var.automatic_upgrade_channel != null || var.node_os_channel_upgrade != null ? {
        upgradeChannel        = var.automatic_upgrade_channel
        nodeOSUpgradeChannel = var.node_os_channel_upgrade
      } : null

      # Security Profile
      securityProfile = var.workload_identity_enabled != null ? {
        workloadIdentity = {
          enabled = var.workload_identity_enabled
        }
      } : null

      # OIDC Issuer Profile
      oidcIssuerProfile = var.oidc_issuer_enabled != null ? {
        enabled = var.oidc_issuer_enabled
      } : null

      # Private Cluster Configuration
      apiServerAccessProfile = var.private_cluster_enabled != null ? {
        enablePrivateCluster = var.private_cluster_enabled
      } : null

      # Addon Profiles
      addonProfiles = {for k, v in {
        azurepolicy = var.azure_policy_enabled != null ? {
          enabled = var.azure_policy_enabled
          config = {
            version = "v2"
          }
        } : null
        
        # ACI Connector Linux Migration
        aciConnectorLinux = var.aci_connector_linux_subnet_name != null ? {
          enabled = true
          config = {
            SubnetName = var.aci_connector_linux_subnet_name
          }
        } : null
      } : k => v if v != null}

      # Metrics Profile  
      metricsProfile = var.cost_analysis_enabled != null ? {
        costAnalysis = {
          enabled = var.cost_analysis_enabled
        }
      } : null
    }
    
    # SKU Configuration
    sku = var.sku_tier != null ? {
      name = "Base"
      tier = var.sku_tier
    } : null
  }

  # Managed Identity Configuration
  identity {
    type = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned,UserAssigned" : var.managed_identities.system_assigned ? "SystemAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "None"
    
    identity_ids = length(var.managed_identities.user_assigned_resource_ids) > 0 ? var.managed_identities.user_assigned_resource_ids : null
  }

  # Tags
  tags = var.tags

  # Lifecycle rules to prevent accidental destruction
  lifecycle {
    ignore_changes = [
      body.properties.kubernetesVersion,
    ]
  }
}

# Data source for resource group
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}
