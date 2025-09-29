package Azure_Proactive_Resiliency_Library_v2

# temporary exemption: azapi plan keeps agentPoolProfiles.* values unknown, so APRL
# cannot observe the availability zone and cluster autoscaler settings that this
# example configures explicitly in Terraform.
exception = [
	["configure_aks_default_node_pool_zones"],
	["aks_enable_cluster_autoscaler"]
]
