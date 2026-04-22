module "default_agent_pool_data" {
  source = "./modules/agentpool"

  name                          = var.default_agent_pool.name
  parent_id                     = "" # As we are outputting data only, parent_id is not required
  availability_zones            = var.default_agent_pool.availability_zones
  capacity_reservation_group_id = var.default_agent_pool.capacity_reservation_group_id
  count_of                      = var.default_agent_pool.count_of
  creation_data                 = var.default_agent_pool.creation_data
  enable_auto_scaling           = var.default_agent_pool.enable_auto_scaling
  enable_encryption_at_host     = var.default_agent_pool.enable_encryption_at_host
  enable_fips                   = var.default_agent_pool.enable_fips
  enable_node_public_ip         = var.default_agent_pool.enable_node_public_ip
  enable_ultra_ssd              = var.default_agent_pool.enable_ultra_ssd
  gateway_profile               = var.default_agent_pool.gateway_profile
  gpu_instance_profile          = var.default_agent_pool.gpu_instance_profile
  gpu_profile                   = var.default_agent_pool.gpu_profile
  host_group_id                 = var.default_agent_pool.host_group_id
  kubelet_config                = var.default_agent_pool.kubelet_config
  kubelet_disk_type             = var.default_agent_pool.kubelet_disk_type
  linux_os_config               = var.default_agent_pool.linux_os_config
  local_dns_profile             = var.default_agent_pool.local_dns_profile
  max_count                     = var.default_agent_pool.max_count
  max_pods                      = var.default_agent_pool.max_pods
  message_of_the_day            = var.default_agent_pool.message_of_the_day
  min_count                     = var.default_agent_pool.min_count
  mode                          = "System"
  network_profile               = var.default_agent_pool.network_profile
  node_labels                   = var.default_agent_pool.node_labels
  node_public_ip_prefix_id      = var.default_agent_pool.node_public_ip_prefix_id
  node_taints                   = var.default_agent_pool.node_taints
  orchestrator_version          = var.default_agent_pool.orchestrator_version
  os_disk_size_gb               = var.default_agent_pool.os_disk_size_gb
  os_disk_type                  = var.default_agent_pool.os_disk_type
  os_sku                        = var.default_agent_pool.os_sku
  os_type                       = "Linux"
  output_data_only              = true
  pod_ip_allocation_mode        = var.default_agent_pool.pod_ip_allocation_mode
  pod_subnet_id                 = var.default_agent_pool.pod_subnet_id
  proximity_placement_group_id  = var.default_agent_pool.proximity_placement_group_id
  scale_down_mode               = var.default_agent_pool.scale_down_mode
  scale_set_eviction_policy     = var.default_agent_pool.scale_set_eviction_policy
  scale_set_priority            = var.default_agent_pool.scale_set_priority
  security_profile              = var.default_agent_pool.security_profile
  spot_max_price                = var.default_agent_pool.spot_max_price
  tags                          = var.tags
  timeouts                      = null # Timeouts are not required for data only output
  type                          = var.default_agent_pool.type
  upgrade_settings              = var.default_agent_pool.upgrade_settings
  virtual_machines_profile      = var.default_agent_pool.virtual_machines_profile
  vm_size                       = var.default_agent_pool.vm_size
  vnet_subnet_id                = var.default_agent_pool.vnet_subnet_id
  windows_profile               = var.default_agent_pool.windows_profile
  workload_runtime              = var.default_agent_pool.workload_runtime
}

# When var.default_agent_pool_managed_as_child is true, the default agent pool is managed
# as an independent child resource using the same create_before_destroy pattern as user
# pools. The first apply after flipping the flag adopts the existing default pool via the
# import block below without making any changes in Azure.
#
# On replacement of immutable fields (e.g. vm_size):
#   1. A new pool is created with a name like "<name><4-char-hash>" (e.g. "default1a2b").
#   2. AKS then deletes the old pool, which cordons and drains its nodes. The Kubernetes
#      scheduler reschedules workloads onto the new pool subject to any PodDisruptionBudget
#      settings. A second mode = "System" pool is not required for the swap itself.
#
# The parent cluster resource keeps `ignore_changes = [body.properties.agentPoolProfiles]`
# so drift on the default pool (now owned by this module) does not cause the parent to
# reconcile it.
module "default_agent_pool" {
  source = "./modules/agentpool"
  count  = var.default_agent_pool_managed_as_child ? 1 : 0

  name = var.default_agent_pool.name
  # parent_id is built from inputs (not a reference to azapi_resource.this.id) so there is
  # no implicit Terraform dependency from this module to the cluster resource. That lets us
  # add an explicit depends_on on the cluster resource (see main.tf) so that on destroy the
  # cluster is destroyed BEFORE this child pool resource. When the cluster is gone, the
  # subsequent pool DELETE returns 404 and azapi treats that as already-deleted.
  #
  # Create-order note: on the initial apply with the flag=true-from-the-start the child
  # pool resource PUT would race the cluster PUT. The module documents that the flag should
  # only be flipped to true on an apply AFTER the cluster already exists (flag=false first
  # apply, then flag=true on a subsequent apply). In that flow the import block adopts the
  # existing pool and no server-side PUT happens for this resource.
  parent_id                     = "${var.parent_id}/providers/Microsoft.ContainerService/managedClusters/${var.name}"
  availability_zones            = var.default_agent_pool.availability_zones
  capacity_reservation_group_id = var.default_agent_pool.capacity_reservation_group_id
  count_of                      = var.default_agent_pool.count_of
  create_before_destroy         = true
  creation_data                 = var.default_agent_pool.creation_data
  enable_auto_scaling           = var.default_agent_pool.enable_auto_scaling
  enable_encryption_at_host     = var.default_agent_pool.enable_encryption_at_host
  enable_fips                   = var.default_agent_pool.enable_fips
  enable_node_public_ip         = var.default_agent_pool.enable_node_public_ip
  enable_ultra_ssd              = var.default_agent_pool.enable_ultra_ssd
  gateway_profile               = var.default_agent_pool.gateway_profile
  gpu_instance_profile          = var.default_agent_pool.gpu_instance_profile
  gpu_profile                   = var.default_agent_pool.gpu_profile
  host_group_id                 = var.default_agent_pool.host_group_id
  kubelet_config                = var.default_agent_pool.kubelet_config
  kubelet_disk_type             = var.default_agent_pool.kubelet_disk_type
  linux_os_config               = var.default_agent_pool.linux_os_config
  local_dns_profile             = var.default_agent_pool.local_dns_profile
  max_count                     = var.default_agent_pool.max_count
  max_pods                      = var.default_agent_pool.max_pods
  message_of_the_day            = var.default_agent_pool.message_of_the_day
  min_count                     = var.default_agent_pool.min_count
  mode                          = "System"
  network_profile               = var.default_agent_pool.network_profile
  node_labels                   = var.default_agent_pool.node_labels
  node_public_ip_prefix_id      = var.default_agent_pool.node_public_ip_prefix_id
  node_taints                   = var.default_agent_pool.node_taints
  orchestrator_version          = var.default_agent_pool.orchestrator_version
  os_disk_size_gb               = var.default_agent_pool.os_disk_size_gb
  os_disk_type                  = var.default_agent_pool.os_disk_type
  os_sku                        = var.default_agent_pool.os_sku
  os_type                       = "Linux"
  output_data_only              = false
  pod_ip_allocation_mode        = var.default_agent_pool.pod_ip_allocation_mode
  pod_subnet_id                 = var.default_agent_pool.pod_subnet_id
  proximity_placement_group_id  = var.default_agent_pool.proximity_placement_group_id
  scale_down_mode               = var.default_agent_pool.scale_down_mode
  scale_set_eviction_policy     = var.default_agent_pool.scale_set_eviction_policy
  scale_set_priority            = var.default_agent_pool.scale_set_priority
  security_profile              = var.default_agent_pool.security_profile
  spot_max_price                = var.default_agent_pool.spot_max_price
  tags                          = var.tags
  timeouts                      = var.agentpool_timeouts
  type                          = var.default_agent_pool.type
  upgrade_settings              = var.default_agent_pool.upgrade_settings
  virtual_machines_profile      = var.default_agent_pool.virtual_machines_profile
  vm_size                       = var.default_agent_pool.vm_size
  vnet_subnet_id                = var.default_agent_pool.vnet_subnet_id
  windows_profile               = var.default_agent_pool.windows_profile
  workload_runtime              = var.default_agent_pool.workload_runtime
}

# Conditional import: adopts the existing default agent pool (created as part of the parent
# cluster PUT) into the child module's create_before_destroy resource instance the first
# time default_agent_pool_managed_as_child is set to true. Import blocks are idempotent --
# on subsequent plans Terraform sees the resource already in state and this is a no-op.
#
# The import id is constructed from known-at-plan-time inputs (var.parent_id, var.name,
# var.default_agent_pool.name) rather than from azapi_resource.this.id, because Terraform
# requires the import id to be fully known during plan. This means the adopted name must
# match the original default pool name used in the parent cluster PUT.
import {
  for_each = var.default_agent_pool_managed_as_child ? toset(["default"]) : toset([])
  to       = module.default_agent_pool[0].azapi_resource.this_create_before_destroy[0]
  id       = "${var.parent_id}/providers/Microsoft.ContainerService/managedClusters/${var.name}/agentPools/${var.default_agent_pool.name}"
}
