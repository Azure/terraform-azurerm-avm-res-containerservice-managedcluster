locals {
  # This is the filtered resource body.
  # If automatic SKU is selected, only a subset of properties are allowed.
  # We also remove any null body.properties.
  resource_body = merge(
    local.resource_body_full,
    {
      properties = local.resource_body_properties
    }
  )
  # This is the full resource body converting snake to camel case.
  resource_body_full = {
    extendedLocation = var.extended_location == null ? null : {
      name = var.extended_location.name
      type = var.extended_location.type
    }
    kind = var.kind
    properties = {
      aadProfile = var.aad_profile == null ? null : {
        adminGroupObjectIDs = var.aad_profile.admin_group_object_ids == null ? null : [for item in var.aad_profile.admin_group_object_ids : item]
        clientAppID         = var.aad_profile.client_app_id
        enableAzureRBAC     = var.aad_profile.enable_azure_rbac
        managed             = var.aad_profile.managed
        serverAppID         = var.aad_profile.server_app_id
        serverAppSecret     = var.aad_profile.server_app_secret
        tenantID            = var.aad_profile.tenant_id
      }
      addonProfiles     = local.addon_profiles
      agentPoolProfiles = local.agent_pool_profiles
      aiToolchainOperatorProfile = var.ai_toolchain_operator_profile == null ? null : {
        enabled = var.ai_toolchain_operator_profile.enabled
      }
      apiServerAccessProfile = var.api_server_access_profile == null ? null : {
        authorizedIPRanges             = var.api_server_access_profile.authorized_ip_ranges == null ? null : [for item in var.api_server_access_profile.authorized_ip_ranges : item]
        disableRunCommand              = var.api_server_access_profile.disable_run_command
        enablePrivateCluster           = var.api_server_access_profile.enable_private_cluster
        enablePrivateClusterPublicFQDN = var.api_server_access_profile.enable_private_cluster_public_fqdn
        enableVnetIntegration          = var.api_server_access_profile.enable_vnet_integration
        privateDNSZone                 = var.api_server_access_profile.private_dns_zone
        subnetId                       = var.api_server_access_profile.subnet_id
      }
      autoScalerProfile = var.auto_scaler_profile == null ? null : {
        balance-similar-node-groups           = var.auto_scaler_profile.balance_similar_node_groups
        daemonset-eviction-for-empty-nodes    = var.auto_scaler_profile.daemonset_eviction_for_empty_nodes
        daemonset-eviction-for-occupied-nodes = var.auto_scaler_profile.daemonset_eviction_for_occupied_nodes
        expander                              = var.auto_scaler_profile.expander
        ignore-daemonsets-utilization         = var.auto_scaler_profile.ignore_daemonsets_utilization
        max-empty-bulk-delete                 = var.auto_scaler_profile.max_empty_bulk_delete
        max-graceful-termination-sec          = var.auto_scaler_profile.max_graceful_termination_sec
        max-node-provision-time               = var.auto_scaler_profile.max_node_provision_time
        max-total-unready-percentage          = var.auto_scaler_profile.max_total_unready_percentage
        new-pod-scale-up-delay                = var.auto_scaler_profile.new_pod_scale_up_delay
        ok-total-unready-count                = var.auto_scaler_profile.ok_total_unready_count
        scale-down-delay-after-add            = var.auto_scaler_profile.scale_down_delay_after_add
        scale-down-delay-after-delete         = var.auto_scaler_profile.scale_down_delay_after_delete
        scale-down-delay-after-failure        = var.auto_scaler_profile.scale_down_delay_after_failure
        scale-down-unneeded-time              = var.auto_scaler_profile.scale_down_unneeded_time
        scale-down-unready-time               = var.auto_scaler_profile.scale_down_unready_time
        scale-down-utilization-threshold      = var.auto_scaler_profile.scale_down_utilization_threshold
        scan-interval                         = var.auto_scaler_profile.scan_interval
        skip-nodes-with-local-storage         = var.auto_scaler_profile.skip_nodes_with_local_storage
        skip-nodes-with-system-pods           = var.auto_scaler_profile.skip_nodes_with_system_pods
      }
      autoUpgradeProfile = var.auto_upgrade_profile == null ? null : {
        nodeOSUpgradeChannel = var.auto_upgrade_profile.node_os_upgrade_channel
        upgradeChannel       = var.auto_upgrade_profile.upgrade_channel
      }
      azureMonitorProfile = var.azure_monitor_profile == null ? null : {
        metrics = var.azure_monitor_profile.metrics == null ? null : {
          enabled = var.azure_monitor_profile.metrics.enabled
          kubeStateMetrics = var.azure_monitor_profile.metrics.kube_state_metrics == null ? null : {
            metricAnnotationsAllowList = var.azure_monitor_profile.metrics.kube_state_metrics.metric_annotations_allow_list
            metricLabelsAllowlist      = var.azure_monitor_profile.metrics.kube_state_metrics.metric_labels_allowlist
          }
        }
      }
      bootstrapProfile = var.bootstrap_profile == null ? null : {
        artifactSource      = var.bootstrap_profile.artifact_source
        containerRegistryId = var.bootstrap_profile.container_registry_id
      }
      disableLocalAccounts = var.disable_local_accounts
      diskEncryptionSetID  = var.disk_encryption_set_id
      dnsPrefix            = var.dns_prefix
      enableRBAC           = var.enable_rbac
      fqdnSubdomain        = var.fqdn_subdomain
      httpProxyConfig = var.http_proxy_config == null ? null : {
        httpProxy  = var.http_proxy_config.http_proxy
        httpsProxy = var.http_proxy_config.https_proxy
        noProxy    = var.http_proxy_config.no_proxy == null ? null : [for item in var.http_proxy_config.no_proxy : item]
        trustedCa  = var.http_proxy_config.trusted_ca
      }
      identityProfile = var.identity_profile == null ? null : { for k, value in var.identity_profile : k => value == null ? null : {
        resourceId = value.resource_id
      } }
      ingressProfile = var.ingress_profile == null ? null : {
        webAppRouting = var.ingress_profile.web_app_routing == null ? null : {
          dnsZoneResourceIds = var.ingress_profile.web_app_routing.dns_zone_resource_ids == null ? null : [for item in var.ingress_profile.web_app_routing.dns_zone_resource_ids : item]
          enabled            = var.ingress_profile.web_app_routing.enabled
          nginx = var.ingress_profile.web_app_routing.nginx == null ? null : {
            defaultIngressControllerType = var.ingress_profile.web_app_routing.nginx.default_ingress_controller_type
          }
        }
      }
      kubernetesVersion = var.kubernetes_version
      linuxProfile = var.linux_profile == null ? null : {
        adminUsername = var.linux_profile.admin_username
        ssh = var.linux_profile.ssh == null ? null : {
          publicKeys = var.linux_profile.ssh.public_keys == null ? null : [for item in var.linux_profile.ssh.public_keys : item == null ? null : {
            keyData = item.key_data
          }]
        }
      }
      metricsProfile = var.metrics_profile == null ? null : {
        costAnalysis = var.metrics_profile.cost_analysis == null ? null : {
          enabled = var.metrics_profile.cost_analysis.enabled
        }
      }
      networkProfile = local.network_profile
      nodeProvisioningProfile = var.node_provisioning_profile == null ? null : {
        defaultNodePools = var.node_provisioning_profile.default_node_pools
        mode             = var.node_provisioning_profile.mode
      }
      nodeResourceGroup = var.node_resource_group
      nodeResourceGroupProfile = var.node_resource_group_profile == null ? null : {
        restrictionLevel = var.node_resource_group_profile.restriction_level
      }
      oidcIssuerProfile = var.oidc_issuer_profile == null ? null : {
        enabled = var.oidc_issuer_profile.enabled
      }
      podIdentityProfile = var.pod_identity_profile == null ? null : {
        allowNetworkPluginKubenet = var.pod_identity_profile.allow_network_plugin_kubenet
        enabled                   = var.pod_identity_profile.enabled
        userAssignedIdentities = var.pod_identity_profile.user_assigned_identities == null ? null : [for item in var.pod_identity_profile.user_assigned_identities : item == null ? null : {
          bindingSelector = item.binding_selector
          identity = item.identity == null ? null : {
            clientId   = item.identity.client_id
            objectId   = item.identity.object_id
            resourceId = item.identity.resource_id
          }
          name      = item.name
          namespace = item.namespace
        }]
        userAssignedIdentityExceptions = var.pod_identity_profile.user_assigned_identity_exceptions == null ? null : [for item in var.pod_identity_profile.user_assigned_identity_exceptions : item == null ? null : {
          name      = item.name
          namespace = item.namespace
          podLabels = item.pod_labels == null ? null : { for k, value in item.pod_labels : k => value }
        }]
      }
      privateLinkResources = var.private_link_resources == null ? null : [for item in var.private_link_resources : item == null ? null : {
        groupId         = item.group_id
        id              = item.id
        name            = item.name
        requiredMembers = item.required_members == null ? null : [for item in item.required_members : item]
        type            = item.type
      }]
      publicNetworkAccess = var.public_network_access
      securityProfile = var.security_profile == null ? null : {
        azureKeyVaultKms = var.security_profile.azure_key_vault_kms == null ? null : {
          enabled               = var.security_profile.azure_key_vault_kms.enabled
          keyId                 = var.security_profile.azure_key_vault_kms.key_id
          keyVaultNetworkAccess = var.security_profile.azure_key_vault_kms.key_vault_network_access
          keyVaultResourceId    = var.security_profile.azure_key_vault_kms.key_vault_resource_id
        }
        customCATrustCertificates = var.security_profile.custom_ca_trust_certificates == null ? null : [for item in var.security_profile.custom_ca_trust_certificates : item]
        defender = var.security_profile.defender == null ? null : {
          logAnalyticsWorkspaceResourceId = var.security_profile.defender.log_analytics_workspace_resource_id
          securityMonitoring = var.security_profile.defender.security_monitoring == null ? null : {
            enabled = var.security_profile.defender.security_monitoring.enabled
          }
        }
        imageCleaner = var.security_profile.image_cleaner == null ? null : {
          enabled       = var.security_profile.image_cleaner.enabled
          intervalHours = var.security_profile.image_cleaner.interval_hours
        }
        workloadIdentity = var.security_profile.workload_identity == null ? null : {
          enabled = var.security_profile.workload_identity.enabled
        }
      }
      serviceMeshProfile = var.service_mesh_profile == null ? null : {
        istio = var.service_mesh_profile.istio == null ? null : {
          certificateAuthority = var.service_mesh_profile.istio.certificate_authority == null ? null : {
            plugin = var.service_mesh_profile.istio.certificate_authority.plugin == null ? null : {
              certChainObjectName = var.service_mesh_profile.istio.certificate_authority.plugin.cert_chain_object_name
              certObjectName      = var.service_mesh_profile.istio.certificate_authority.plugin.cert_object_name
              keyObjectName       = var.service_mesh_profile.istio.certificate_authority.plugin.key_object_name
              keyVaultId          = var.service_mesh_profile.istio.certificate_authority.plugin.key_vault_id
              rootCertObjectName  = var.service_mesh_profile.istio.certificate_authority.plugin.root_cert_object_name
            }
          }
          components = var.service_mesh_profile.istio.components == null ? null : {
            egressGateways = var.service_mesh_profile.istio.components.egress_gateways == null ? null : [for item in var.service_mesh_profile.istio.components.egress_gateways : item == null ? null : {
              enabled                  = item.enabled
              gatewayConfigurationName = item.gateway_configuration_name
              name                     = item.name
              namespace                = item.namespace
            }]
            ingressGateways = var.service_mesh_profile.istio.components.ingress_gateways == null ? null : [for item in var.service_mesh_profile.istio.components.ingress_gateways : item == null ? null : {
              enabled = item.enabled
              mode    = item.mode
            }]
          }
          revisions = var.service_mesh_profile.istio.revisions == null ? null : [for item in var.service_mesh_profile.istio.revisions : item]
        }
        mode = var.service_mesh_profile.mode
      }
      servicePrincipalProfile = var.service_principal_profile == null ? null : {
        clientId = var.service_principal_profile.client_id
        secret   = var.service_principal_profile.secret
      }
      storageProfile = var.storage_profile == null ? null : {
        blobCSIDriver = var.storage_profile.blob_csi_driver == null ? null : {
          enabled = var.storage_profile.blob_csi_driver.enabled
        }
        diskCSIDriver = var.storage_profile.disk_csi_driver == null ? null : {
          enabled = var.storage_profile.disk_csi_driver.enabled
        }
        fileCSIDriver = var.storage_profile.file_csi_driver == null ? null : {
          enabled = var.storage_profile.file_csi_driver.enabled
        }
        snapshotController = var.storage_profile.snapshot_controller == null ? null : {
          enabled = var.storage_profile.snapshot_controller.enabled
        }
      }
      supportPlan = var.support_plan
      upgradeSettings = var.upgrade_settings == null ? null : {
        overrideSettings = var.upgrade_settings.override_settings == null ? null : {
          forceUpgrade = var.upgrade_settings.override_settings.force_upgrade
          until        = var.upgrade_settings.override_settings.until
        }
      }
      windowsProfile = var.windows_profile == null ? null : {
        adminUsername  = var.windows_profile.admin_username
        enableCSIProxy = var.windows_profile.enable_csi_proxy
        gmsaProfile = var.windows_profile.gmsa_profile == null ? null : {
          dnsServer      = var.windows_profile.gmsa_profile.dns_server
          enabled        = var.windows_profile.gmsa_profile.enabled
          rootDomainName = var.windows_profile.gmsa_profile.root_domain_name
        }
        licenseType = var.windows_profile.license_type
      }
      workloadAutoScalerProfile = var.workload_auto_scaler_profile == null ? null : {
        keda = var.workload_auto_scaler_profile.keda == null ? null : {
          enabled = var.workload_auto_scaler_profile.keda.enabled
        }
        verticalPodAutoscaler = var.workload_auto_scaler_profile.vertical_pod_autoscaler == null ? null : {
          enabled = var.workload_auto_scaler_profile.vertical_pod_autoscaler.enabled
        }
      }
    }
    sku = var.sku == null ? null : {
      name = var.sku.name
      tier = var.sku.tier
    }
  }
  # Why regex? Because Terraform required that ternary expressions return the same type.
  # This is also try for functions like concat(), etc.
  # Therefore, we use regex to filter the properties accordingly.
  # The only ternary we use is a string for the regex pattern.
  resource_body_properties = {
    for k, v in local.resource_body_full.properties : k => v if can(regex(local.resource_body_properties_regex, k)) && v != null
  }
  resource_body_properties_automatic = [
    "addonProfiles",
    "agentPoolProfiles",
    "apiServerAccessProfile",
    "azureMonitorProfile",
    "diskEncryptionSetID",
    "ingressProfile",
    "kubernetesVersion",
    "metricsProfile",
    "networkProfile",
    "nodeResourceGroup",
    "serviceMeshProfile",
    "storageProfile",
  ]
  resource_body_properties_regex           = local.is_automatic ? local.resource_body_properties_regex_automatic : local.resource_body_properties_regex_standard
  resource_body_properties_regex_automatic = "^(${join("|", local.resource_body_properties_automatic)})$"
  resource_body_properties_regex_standard  = "^(.*)$"
}
