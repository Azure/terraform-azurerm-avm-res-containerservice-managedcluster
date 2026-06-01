# Application Gateway for Containers with AKS BYO deployment

This example deploys Application Gateway for Containers alongside a private AKS cluster using the Bring Your Own (BYO) deployment strategy. It demonstrates the recommended Azure infrastructure setup based on the [AKS Secure Baseline Private Cluster](https://github.com/Azure/AKS-Landing-Zone-Accelerator/tree/main/Scenarios/AKS-Secure-Baseline-PrivateCluster) pattern.

## What this deploys

- Virtual network with three subnets: AKS nodes, Application Gateway for Containers association, and API server VNet integration
- Private AKS cluster with Azure CNI, Workload Identity, and OIDC issuer enabled
- Application Gateway for Containers with one frontend and one association
- User-assigned managed identities with the required RBAC roles for AKS and the ALB Controller
