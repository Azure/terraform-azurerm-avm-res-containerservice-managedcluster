# Private AKS Automatic example

This deploys a private AKS Automatic cluster in a custom virtual network, including API server and node subnets, private DNS zone, user-assigned identity with role assignments, Log Analytics + Azure Monitor workspace, and default monitoring/alerts.

To connect to the private cluster after deployment, use one of the supported methods described in the [Azure documentation on connecting to a private cluster](https://learn.microsoft.com/azure/aks/private-cluster-connect?pivots=azure-cloud-shell).

> Note: To use the `az aks command invoke` command to run commands on the cluster, the `disable_run_command` property in the `api_server_access_profile` module variable must be set to `false`.
