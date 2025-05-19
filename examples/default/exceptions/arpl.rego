package Azure_Proactive_Resiliency_Library_v2

import rego.v1

exception contains rules if {
  rules = ["configure_aks_default_node_pool_zones", "aks_enable_cluster_autoscaler", "aks_user_pool_min_node_count", "aks_system_pool_min_node_count"]
}
