provider "azapi" {
  subscription_id = local.subscription_id
}

# Published prerequisite AVM modules require AzureRM; the AKS module itself uses AzAPI.
provider "azurerm" {
  subscription_id                 = local.subscription_id
  resource_provider_registrations = "none"

  features {
    key_vault {
      purge_soft_delete_on_destroy       = false
      purge_soft_deleted_keys_on_destroy = false
      recover_soft_deleted_key_vaults    = false
      recover_soft_deleted_keys          = false
    }
  }
}

resource "random_string" "name_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Fresh role assignments can take minutes to propagate; AKS validates BYO identity
# permissions at create time.
resource "time_sleep" "rbac_propagation" {
  create_duration = "60s"

  depends_on = [module.prerequisite_role_assignments]
}

# Each attribute below is annotated with the FINOS CCC K8S assessment requirements (ARs)
# it enforces. See _header.md for the complete control matrix and residual items.
module "aks" {
  source = "../.."

  # CCC.Core.CN06: approved region.
  location  = var.location
  name      = local.cluster_name
  parent_id = local.resource_group_id
  # CCC.K8S.CN02.AR01 / CN16.AR01: Entra ID with Azure RBAC for Kubernetes authorization.
  # Admin groups are reserved for break-glass access.
  aad_profile = {
    managed                = true
    enable_azure_rbac      = true
    admin_group_object_ids = var.cluster_admin_group_object_ids
  }
  # CCC.K8S.CN04/CN05/CN11/CN13: the Azure Policy add-on enforces the assignments in
  # main.governance.tf. CCC.K8S.CN08.AR01: add-ons come from the allowlist check below.
  addon_profile_azure_policy = local.addon_profile_azure_policy
  # CCC.K8S.CN14.AR01: Container Insights with Entra ID authentication.
  addon_profile_oms_agent = {
    enabled = local.addon_profile_oms_agent_enabled
    config = {
      log_analytics_workspace_resource_id = module.log_analytics.resource_id
      use_aad_auth                        = true
    }
  }
  # CCC.K8S.CN01.AR01/AR02, CCC.Core.CN05: private API server reachable only from the
  # cluster VNet; no public FQDN and no Run Command.
  api_server_access_profile = {
    enable_private_cluster             = true
    enable_private_cluster_public_fqdn = false
    enable_vnet_integration            = true
    disable_run_command                = true
    private_dns_zone                   = local.private_dns_zone_id
    subnet_id                          = local.api_server_subnet_id
  }
  # CCC.K8S.CN09.AR01/AR02: managed patch and node-image upgrades.
  auto_upgrade_profile = {
    upgrade_channel         = "patch"
    node_os_upgrade_channel = "NodeImage"
  }
  # CCC.K8S.CN12.AR02: SSH disabled, no public node IPs.
  # CCC.K8S.CN18.AR01/AR02: AKS-supplied image with Secure Boot and vTPM (Trusted Launch).
  # CCC.Core.CN02: encryption at host in addition to the DES.
  # CCC.K8S.CN13.AR03: autoscaler with an explicit maximum.
  default_agent_pool = {
    name                      = "systempool"
    vm_size                   = "Standard_D4s_v5"
    count_of                  = 2
    min_count                 = 2
    max_count                 = 5
    max_pods                  = 30
    vnet_subnet_id            = local.node_subnet_id
    os_sku                    = "Ubuntu"
    os_disk_type              = "Managed"
    enable_auto_scaling       = true
    enable_encryption_at_host = true
    enable_node_public_ip     = false
    availability_zones        = ["1", "2", "3"]
    security_profile = {
      enable_secure_boot = true
      enable_vtpm        = true
      ssh_access         = "Disabled"
    }
  }
  # CCC.K8S.CN14.AR01 / CCC.Core.CN04: Kubernetes audit and control-plane logs to an
  # external Log Analytics workspace.
  diagnostic_settings = {
    log_analytics = {
      name                           = "ds-aks-ccc"
      workspace_resource_id          = module.log_analytics.resource_id
      log_analytics_destination_type = "Dedicated"
      log_groups                     = ["allLogs"]
    }
  }
  # CCC.K8S.CN16.AR02: no local accounts or static credentials.
  disable_local_accounts = true
  # CCC.Core.CN02 / CCC.K8S.CN07.AR01: customer-managed key for node disks.
  disk_encryption_set_id = local.disk_encryption_set_id
  enable_rbac            = true
  enable_telemetry       = var.enable_telemetry
  # CCC.K8S.CN17.AR01: kubelet identity distinct from the control-plane identity.
  identity_profile = {
    kubeletidentity = {
      resource_id = local.kubelet_identity_id
    }
  }
  ignore_body_changes = var.ignore_body_changes.containerservice_managed_clusters
  # CCC.K8S.CN09.AR01: a <major.minor> or null version lets the patch channel keep the
  # cluster inside the support lifecycle without idempotency drift.
  kubernetes_version = var.kubernetes_version
  # CCC.K8S.CN09.AR02: upgrades run inside weekly maintenance windows.
  maintenanceconfiguration = {
    aksManagedAutoUpgradeSchedule = {
      name = "aksManagedAutoUpgradeSchedule"
      maintenance_window = {
        duration_hours = 4
        start_time     = "00:00"
        utc_offset     = "+00:00"
        schedule = {
          weekly = {
            day_of_week    = "Sunday"
            interval_weeks = 1
          }
        }
        # A fixed past date: without it AKS stores today's date and every plan drifts.
        start_date = "2026-01-04"
      }
    }
    aksManagedNodeOSUpgradeSchedule = {
      name = "aksManagedNodeOSUpgradeSchedule"
      maintenance_window = {
        duration_hours = 4
        start_time     = "00:00"
        utc_offset     = "+00:00"
        schedule = {
          weekly = {
            day_of_week    = "Saturday"
            interval_weeks = 1
          }
        }
        start_date = "2026-01-03"
      }
    }
  }
  # CCC.K8S.CN17.AR01: dedicated control-plane identity.
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [local.control_plane_identity_id]
  }
  # CCC.K8S.CN06.AR01, CN12.AR03, CN13.AR02, CN15.AR01: managed namespaces with
  # default-deny network policy (which also blocks IMDS), quotas and ownership metadata.
  namespace = {
    for key, ns in var.workload_namespaces : key => {
      name = key
      labels = merge(ns.labels, {
        "data-classification" = ns.data_classification
      })
      annotations = {
        "ccc.finos.org/owner" = ns.owner
      }
      default_network_policy = {
        ingress = "DenyAll"
        egress  = "DenyAll"
      }
      default_resource_quota = ns.resource_quota
      adoption_policy        = "Never"
      delete_policy          = "Delete"
      tags                   = var.tags
    }
  }
  # CCC.K8S.CN06: Cilium enforces the namespace network policies.
  network_profile = {
    load_balancer_sku   = "standard"
    outbound_type       = var.outbound_type
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_dataplane   = "cilium"
    network_policy      = "cilium"
    pod_cidr            = "172.18.0.0/16"
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }
  # CCC.K8S.CN15.AR02: block out-of-band changes to the AKS-managed node resource group.
  node_resource_group_profile = {
    restriction_level = "ReadOnly"
  }
  # CCC.K8S.CN03.AR01: OIDC issuer for federated workload identities.
  oidc_issuer_profile = {
    enabled = local.enabled_cluster_features.workload_identity
  }
  # CCC.K8S.CN01.AR02: public network access to the API server is disabled.
  public_network_access = "Disabled"
  resource_types        = var.resource_types.containerservice_managed_clusters
  retry                 = var.retry
  # CCC.K8S.CN02.AR01: scoped Azure RBAC for Kubernetes role assignments. Nothing is granted
  # by default, not even to the deployer.
  role_assignments = var.cluster_role_assignments
  # CCC.K8S.CN03.AR01: workload identity. CCC.K8S.CN07.AR01: private Key Vault KMS for
  # Kubernetes secrets. CCC.K8S.CN14.AR01 / CCC.Core.CN07: Defender threat detection.
  security_profile = {
    workload_identity = {
      enabled = local.enabled_cluster_features.workload_identity
    }
    azure_key_vault_kms = {
      enabled                  = local.enabled_cluster_features.azure_key_vault_kms
      key_id                   = local.key_vault_key_id
      key_vault_network_access = "Private"
      key_vault_resource_id    = local.key_vault_resource_id
    }
    defender = {
      log_analytics_workspace_resource_id = module.log_analytics.resource_id
      security_monitoring = {
        enabled = local.enabled_cluster_features.defender
      }
    }
    image_cleaner = {
      enabled        = local.enabled_cluster_features.image_cleaner
      interval_hours = 48
    }
  }
  # CCC.K8S.CN09: Standard tier with an uptime SLA.
  sku = {
    name = "Base"
    tier = "Standard"
  }
  # CCC.K8S.CN08.AR01: only the approved storage drivers (AKS enables more by default).
  storage_profile = {
    for name, enabled in local.enabled_storage_features : name => { enabled = enabled }
  }
  # CCC.K8S.CN15.AR01: approved ownership, environment and data-classification tags.
  tags     = var.tags
  timeouts = var.timeouts

  depends_on = [
    terraform_data.approved_addons,
    time_sleep.rbac_propagation,
    module.api_dns_zone,
  ]
}

# CCC.K8S.CN08.AR01: plan fails before the cluster is created when the example would enable
# an add-on or managed feature that is not in var.approved_addons.
resource "terraform_data" "approved_addons" {
  input = local.enabled_addons

  lifecycle {
    precondition {
      condition     = length(setsubtract(local.enabled_addons, var.approved_addons)) == 0
      error_message = "CCC.K8S.CN08.AR01: these configured add-ons are not in var.approved_addons: ${join(", ", setsubtract(local.enabled_addons, var.approved_addons))}."
    }
  }
}

# CCC.K8S.CN08.AR01: reads the deployed cluster back, so add-ons the module or AKS enable by
# default are checked too. Apply (and every later plan) fails when AKS reports an enabled
# add-on or managed feature outside var.approved_addons.
data "azapi_resource" "cluster_features" {
  resource_id = module.aks.resource_id
  type        = coalesce(var.resource_types.containerservice_managed_clusters.containerservice_managed_clusters, "Microsoft.ContainerService/managedClusters@2026-03-01")
  response_export_values = [
    "properties.addonProfiles",
    "properties.azureMonitorProfile",
    "properties.ingressProfile",
    "properties.securityProfile",
    "properties.serviceMeshProfile",
    "properties.storageProfile",
    "properties.workloadAutoScalerProfile",
  ]
}

resource "terraform_data" "observed_addons" {
  input = local.observed_addons

  lifecycle {
    precondition {
      condition     = length(setsubtract(local.observed_addons, var.approved_addons)) == 0
      error_message = "CCC.K8S.CN08.AR01: the cluster has add-ons or managed features enabled that are not in var.approved_addons: ${join(", ", setsubtract(local.observed_addons, var.approved_addons))}."
    }
  }
}
