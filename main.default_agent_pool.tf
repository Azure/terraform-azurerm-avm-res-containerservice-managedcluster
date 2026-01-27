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

# This is in place so we can update the default agent pool, as we ignore changes to the object array in the parent resource.
# TODO: Remove this when <https://github.com/Azure/terraform-provider-azapi/pull/1033> is merged and released.
resource "azapi_update_resource" "default_agent_pool" {
  name      = module.default_agent_pool_data.name
  parent_id = azapi_resource.this.id
  type      = "Microsoft.ContainerService/managedClusters/agentpools@2025-10-01"
  body = {
    properties = { for k, v in module.default_agent_pool_data.body_properties : k => v if v != null }
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
