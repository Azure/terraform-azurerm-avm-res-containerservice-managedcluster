# Private AKS Automatic example

This deploys a private AKS Automatic cluster in a customer-owned (BYO) virtual network. The example provisions API server, user-node and system-node subnets, a private DNS zone, a user-assigned identity with role assignments, a Log Analytics + Azure Monitor workspace, and default monitoring/alerts. The `hosted_system_profile` input wires the user and system subnets into the hosted system components required when bringing your own virtual network to AKS Automatic.

To connect to the private cluster after deployment, use one of the supported methods described in the [Azure documentation on connecting to a private cluster](https://learn.microsoft.com/azure/aks/private-cluster-connect?pivots=azure-cloud-shell).

> Note: To use the `az aks command invoke` command to run commands on the cluster, the `disable_run_command` property in the `api_server_access_profile` module variable must be set to `false`.
