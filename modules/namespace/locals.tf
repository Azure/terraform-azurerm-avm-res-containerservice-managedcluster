locals {
  resource_body = {
    properties = {
      adoptionPolicy = var.adoption_policy
      annotations    = var.annotations == null ? null : { for k, value in var.annotations : k => value }
      defaultNetworkPolicy = var.default_network_policy == null ? null : {
        egress  = var.default_network_policy.egress
        ingress = var.default_network_policy.ingress
      }
      defaultResourceQuota = var.default_resource_quota == null ? null : {
        cpuLimit      = var.default_resource_quota.cpu_limit
        cpuRequest    = var.default_resource_quota.cpu_request
        memoryLimit   = var.default_resource_quota.memory_limit
        memoryRequest = var.default_resource_quota.memory_request
      }
      deletePolicy = var.delete_policy
      labels       = var.labels == null ? null : { for k, value in var.labels : k => value }
    }
  }
}
