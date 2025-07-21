variable "cluster_resource_id" {
  type        = string
  description = "Resource ID of the existing Kubernetes cluster."
}

# Main properties
variable "name" {
  type        = string
  description = "Required. The name of the Kubernetes nodepool."

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 12
    error_message = "The name of the nodepool must be between 1 and 12 characters in length."
  }
  validation {
    condition     = can(regex("^[a-zA-Z0-9]+$", var.name))
    error_message = "The name of the nodepool must only contain letters and numbers."
  }
}

variable "network_plugin_mode" {
  type        = string
  description = "The network plugin mode for the nodepool."
}

variable "vm_size" {
  type        = string
  description = "Required. The size of the VMs for the nodepool."
}

variable "auto_scaling_enabled" {
  type        = bool
  default     = false
  description = "Optional. Whether or not auto-scaling is enabled."
}

variable "capacity_reservation_group_id" {
  type        = string
  default     = null
  description = "The ID of the capacity reservation group."
}

variable "create_nodepool_before_destroy" {
  type        = bool
  default     = false
  description = "Whether or not to create node pools before destroying the old ones. This is the opposite of the default behavior. Set this to true if zero downtime is required during nodepool redeployments such as changes to snapshot_id."
}

variable "eviction_policy" {
  type        = string
  default     = null
  description = "Optional. The eviction policy for the nodepool."
}

variable "fips_enabled" {
  type        = bool
  default     = null
  description = "Optional. Whether or not FIPS is enabled."
}

variable "gpu_instance" {
  type        = string
  default     = null
  description = "Optional. The GPU instance type for the nodepool."
}

variable "host_encryption_enabled" {
  type        = bool
  default     = null
  description = "Optional. Whether or not host encryption is enabled."
}

variable "host_group_id" {
  type        = string
  default     = null
  description = "Optional. The ID of the host group."
}

# Kubelet config
variable "kubelet_config" {
  type = object({
    cpu_manager_policy        = string
    cpu_cfs_quota_enabled     = bool
    cpu_cfs_quota_period      = string
    image_gc_high_threshold   = number
    image_gc_low_threshold    = number
    topology_manager_policy   = string
    allowed_unsafe_sysctls    = set(string)
    container_log_max_size_mb = number
    container_log_max_line    = number
    pod_max_pid               = number
  })
  default     = null
  description = "Optional. The Kubelet config for the nodepool."
}

variable "kubelet_disk_type" {
  type        = string
  default     = null
  description = "Optional. The disk type for the kubelet."
}

# Linux OS config
variable "linux_os_config" {
  type = object({
    swap_file_size_mb             = optional(number)
    transparent_huge_page_defrag  = optional(string)
    transparent_huge_page_enabled = optional(string)
    sysctl_config = object({
      fs_aio_max_nr                      = optional(number)
      fs_file_max                        = optional(number)
      fs_inotify_max_user_watches        = optional(number)
      fs_nr_open                         = optional(number)
      kernel_threads_max                 = optional(number)
      net_core_netdev_max_backlog        = optional(number)
      net_core_optmem_max                = optional(number)
      net_core_rmem_default              = optional(number)
      net_core_rmem_max                  = optional(number)
      net_core_somaxconn                 = optional(number)
      net_core_wmem_default              = optional(number)
      net_core_wmem_max                  = optional(number)
      net_ipv4_ip_local_port_range_min   = optional(number)
      net_ipv4_ip_local_port_range_max   = optional(number)
      net_ipv4_neigh_default_gc_thresh1  = optional(number)
      net_ipv4_neigh_default_gc_thresh2  = optional(number)
      net_ipv4_neigh_default_gc_thresh3  = optional(number)
      net_ipv4_tcp_fin_timeout           = optional(number)
      net_ipv4_tcp_keepalive_intvl       = optional(number)
      net_ipv4_tcp_keepalive_probes      = optional(number)
      net_ipv4_tcp_keepalive_time        = optional(number)
      net_ipv4_tcp_max_syn_backlog       = optional(number)
      net_ipv4_tcp_max_tw_buckets        = optional(number)
      net_ipv4_tcp_tw_reuse              = optional(bool)
      net_netfilter_nf_conntrack_buckets = optional(number)
      net_netfilter_nf_conntrack_max     = optional(number)
      vm_max_map_count                   = optional(number)
      vm_swappiness                      = optional(number)
      vm_vfs_cache_pressure              = optional(number)
    })
  })
  default     = null
  description = "Optional. The Linux OS config for the nodepool."
}

variable "max_count" {
  type        = number
  default     = null
  description = "Optional. The maximum number of nodes for the nodepool if auto-scaling is enabled."
}

variable "max_pods" {
  type        = number
  default     = null
  description = "Optional. The maximum number of pods per node."
}

variable "min_count" {
  type        = number
  default     = null
  description = "Optional. The minimum number of nodes for the nodepool if auto-scaling is enabled."
}

variable "mode" {
  type        = string
  default     = null
  description = "Optional. The mode for the nodepool."
}

variable "node_count" {
  type        = number
  default     = null
  description = "Optional. The number of nodes for the nodepool. Set to 0 if auto-scaling is enabled."
}

# Additional main properties
variable "node_labels" {
  type        = map(string)
  default     = null
  description = "Optional. The labels for the nodepool."
}

# Nested node network profile
variable "node_network_profile" {
  type = object({
    allowed_host_ports = list(object({
      port_start = number
      port_end   = number
      protocol   = string
    }))
    application_security_group_ids = list(string)
    node_public_ip_tags            = map(string)
  })
  default     = null
  description = "Optional. The network profile for the nodepool."
}

variable "node_public_ip_enabled" {
  type        = bool
  default     = null
  description = "Optional. Whether or not public IPs are enabled for the nodepool."
}

variable "node_public_ip_prefix_id" {
  type        = string
  default     = null
  description = "Optional. The ID of the public IP prefix."
}

variable "node_taints" {
  type        = list(string)
  default     = null
  description = "Optional. The taints for the nodepool."
}

variable "orchestrator_version" {
  type        = string
  default     = null
  description = "Optional. The Kubernetes version for the nodepool."
}

variable "os_disk_size_gb" {
  type        = number
  default     = null
  description = "Optional. The size of the OS disk for the nodepool."
}

variable "os_disk_type" {
  type        = string
  default     = null
  description = "Optional. The type of the OS disk for the nodepool."
}

variable "os_sku" {
  type        = string
  default     = null
  description = "Optional. The SKU of the OS for the nodepool."
}

variable "os_type" {
  type        = string
  default     = null
  description = "Optional. The type of the OS for the nodepool."
}

variable "pod_subnet_id" {
  type        = string
  default     = null
  description = "Optional. The ID of the pod subnet."
}

variable "priority" {
  type        = string
  default     = null
  description = "Optional. The priority for the nodepool."
}

variable "proximity_placement_group_id" {
  type        = string
  default     = null
  description = "Optional. The ID of the proximity placement group."
}

variable "scale_down_mode" {
  type        = string
  default     = null
  description = "Optional. The scale down mode for the nodepool."
}

variable "snapshot_id" {
  type        = string
  default     = null
  description = "Optional. The ID of the snapshot."
}

variable "spot_max_price" {
  type        = string
  default     = null
  description = "Optional. The maximum price for spot instances."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Optional. A mapping of tags to assign to the resource."
}

variable "temporary_name_for_rotation" {
  type        = string
  default     = null
  description = "Optional. Specifies the name of the temporary node pool used to cycle the node pool when one of the relevant properties are updated."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 60 minutes) Used when creating the Kubernetes Cluster Node Pool.
 - `delete` - (Defaults to 60 minutes) Used when deleting the Kubernetes Cluster Node Pool.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Kubernetes Cluster Node Pool.
 - `update` - (Defaults to 60 minutes) Used when updating the Kubernetes Cluster Node Pool.
EOT
}

variable "ultra_ssd_enabled" {
  type        = bool
  default     = null
  description = "Optional. Whether or not ultra SSD is enabled."
}

# Upgrade settings
variable "upgrade_settings" {
  type = object({
    drain_timeout_in_minutes      = optional(number)
    node_soak_duration_in_minutes = optional(number)
    max_surge                     = optional(string)
  })
  default = {
    max_surge = "10%"
  }
  description = "Optional. The upgrade settings for the nodepool."
}

variable "vnet_subnet_id" {
  type        = string
  default     = null
  description = "Optional. The ID of the VNet subnet."
}

# Windows profile
variable "windows_profile" {
  type = object({
    outbound_nat_enabled = bool
  })
  default     = null
  description = "Optional. The Windows profile for the nodepool."
}

variable "workload_runtime" {
  type        = string
  default     = null
  description = "Optional. The workload runtime for the nodepool."
}

variable "zones" {
  type        = list(string)
  default     = null
  description = "Optional. The availability zones for the nodepool."
}
