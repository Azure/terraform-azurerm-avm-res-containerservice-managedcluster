# AKS Secure Baseline Private Cluster with Application Gateway for Containers

This example deploys Application Gateway for Containers alongside a private AKS cluster using the Bring Your Own (BYO) deployment strategy. It demonstrates the recommended Azure infrastructure setup based on the [AKS Secure Baseline Private Cluster](https://github.com/Azure/AKS-Landing-Zone-Accelerator/tree/main/Scenarios/AKS-Secure-Baseline-PrivateCluster) pattern.

## What this deploys

- Virtual network with three subnets: AKS nodes, Application Gateway for Containers association, and API server VNet integration
- Private AKS cluster with Azure CNI, Workload Identity, and OIDC issuer enabled
- Application Gateway for Containers with one frontend and one association
- User-assigned managed identity for AKS plus the add-on-created ALB Controller identity, with the required RBAC roles

## End-to-end validation

Terraform enables the managed Gateway API and Application Gateway for Containers ALB Controller add-ons. It also grants the add-on-created identity the roles it needs to manage the BYO traffic controller and delegated subnet.

```bash
# Verify the ALB Controller pods are running
az aks command invoke -g <resource_group_name> -n <aks_cluster_name> \
  --command "kubectl get pods -n kube-system | grep alb-controller"

# Apply Kubernetes Gateway API resources (GatewayClass, Gateway, HTTPRoute)
# See: https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-byo-deployment
```

This preview feature requires the `ManagedGatewayAPIPreview` and `ApplicationLoadBalancerPreview` subscription features before deployment. The E2E pre-hook verifies both registrations:

```bash
az feature register --namespace Microsoft.ContainerService --name ManagedGatewayAPIPreview
az feature register --namespace Microsoft.ContainerService --name ApplicationLoadBalancerPreview
```

For a consumer with an existing hub-spoke network, replace the inline virtual network and subnet resources with references to existing subnet IDs.
