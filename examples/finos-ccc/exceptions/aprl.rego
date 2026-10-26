package Azure_Proactive_Resiliency_Library_v2

import rego.v1

# The AzAPI plan leaves module.aks.azapi_resource.this agentPoolProfiles values unknown
# (the default pool references subnets and identities created in the same apply), so
# APRL cannot observe settings this example configures explicitly on default_agent_pool:
# availability_zones = ["1", "2", "3"] and enable_auto_scaling = true (min 2, max 5).
# Same exemption, for the same reason, as the other examples in this repository.
exception contains rules if {
  rules = ["configure_aks_default_node_pool_zones", "aks_enable_cluster_autoscaler"]
}
