# AKS Secure Baseline Private Cluster with Application Gateway for Containers

This example deploys Application Gateway for Containers alongside a private AKS cluster using the Bring Your Own (BYO) deployment strategy. It demonstrates the recommended Azure infrastructure setup based on the [AKS Secure Baseline Private Cluster](https://github.com/Azure/AKS-Landing-Zone-Accelerator/tree/main/Scenarios/AKS-Secure-Baseline-PrivateCluster) pattern.

## What this deploys

- Virtual network with three subnets: AKS nodes, Application Gateway for Containers association, and API server VNet integration
- Private AKS cluster with Azure CNI, Workload Identity, and OIDC issuer enabled
- Application Gateway for Containers with one frontend and one association
- User-assigned managed identities with the required RBAC roles for AKS and the ALB Controller

## Post-deployment steps

After Terraform completes, enable the ALB Controller managed add-on and configure Gateway API resources:

```bash
# 1. Enable the ALB Controller add-on on the AKS cluster
az aks update -g <resource_group_name> -n <aks_cluster_name> --enable-alb-controller

# 2. Verify ALB Controller pods are running
az aks command invoke -g <resource_group_name> -n <aks_cluster_name> \
  --command "kubectl get pods -n alb-system"

# 3. Apply Kubernetes Gateway API resources (GatewayClass, Gateway, HTTPRoute)
# See: https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-byo-deployment
```

For a consumer with an existing hub-spoke network, replace the inline virtual network and subnet resources with references to existing subnet IDs.
