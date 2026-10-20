# FINOS CCC-aligned private AKS cluster

This example deploys the AVM AKS resource module (`source = "../.."`) configured against the
[FINOS Common Cloud Controls (CCC) Kubernetes catalog](https://github.com/finos/common-cloud-controls/blob/443b0a2b27e2d9bdfe0abb2eb65a1865e5dbe416/catalogs/orchestration/k8s/controls.yaml)
and the CCC Core controls it imports. Every supporting resource uses a published Azure Verified
Module where one exists. Each Terraform block is annotated with the CCC assessment
requirements (ARs) it enforces.

> **Not an attestation.** The table below records which configuration enforces each AR. It is not an official CCC assessment, and live requirement results still need testing in the deployed environment.

## What it deploys

| Purpose | Module | CCC |
| --- | --- | --- |
| AKS cluster, managed namespaces and maintenance windows | this module (`../..`) | all |
| Resource group | `Azure/avm-res-resources-resourcegroup/azurerm` | Core.CN06 |
| Cluster and runner VNets, subnets | `Azure/avm-res-network-virtualnetwork/azurerm` | CN01, Core.CN05 |
| One NSG per subnet | `Azure/avm-res-network-networksecuritygroup/azurerm` | CN01, Core.CN05 |
| Control-plane, kubelet and workload identities | `Azure/avm-res-managedidentity-userassignedidentity/azurerm` | CN03, CN17 |
| API server, vault and registry private DNS | `Azure/avm-res-network-privatednszone/azurerm` | CN01 |
| Private Key Vault, KMS key and disk key | `Azure/avm-res-keyvault-vault/azurerm` (+ `//modules/key`) | CN07, Core.CN02 |
| Runner vault private endpoint | `Azure/avm-res-network-privateendpoint/azurerm` | CN07 |
| Disk encryption set | `Azure/avm-res-compute-diskencryptionset/azurerm` | Core.CN02 |
| Least-privilege infrastructure grants | `Azure/avm-res-authorization-roleassignment/azurerm` | CN17 |
| Private approved registry | `Azure/avm-res-containerregistry-registry/azurerm` | CN04 |
| Azure Policy for Kubernetes assignments | `Azure/avm-ptn-policyassignment/azurerm` | CN04, CN05, CN11, CN13 |
| Log Analytics workspace | `Azure/avm-res-operationalinsights-workspace/azurerm` | CN14, Core.CN04 |
| Activity log alert | `Azure/avm-res-insights-activitylogalert/azurerm` | CN14, CN11, CN15 |
| Kubernetes audit log alert | `azapi_resource` (`avm-res-insights-scheduledqueryrule` is only Proposed) | CN14 |

## CCC control mapping

Legend: **TF** enforced by Terraform-managed Azure configuration, **Policy** enforced at
admission by Azure Policy for Kubernetes, **K8s** enforced by Kubernetes objects created by the
example, **Residual** requires an operational process or is a platform limitation.

| AR | Enforcement | How |
| --- | --- | --- |
| CN01.AR01 | TF | Private cluster with API-server VNet integration; NSGs on every subnet. |
| CN01.AR02 | TF | `public_network_access = "Disabled"`, no public FQDN, Run Command disabled. |
| CN02.AR01 | TF | Entra ID with Azure RBAC for Kubernetes; scoped `cluster_role_assignments`; admin groups only for break-glass. |
| CN02.AR02 | Residual | Only built-in AKS RBAC roles are granted. Workload `Role` definitions belong to application teams and need review in CI. |
| CN03.AR01 | TF | OIDC issuer, workload identity and one federated identity per workload namespace service account. |
| CN03.AR02 | Residual | Scan manifests, Secrets and ConfigMaps for static credentials in CI. |
| CN04.AR01 | Policy | Allowed images: the private registry only, pinned by `@sha256` digest. |
| CN04.AR02 | Residual | Sign images in the build pipeline. AKS Image Integrity is preview and audit-only, so it is not enabled. |
| CN04.AR03 | Residual | Defender for Containers reports vulnerabilities; gate releases on them in the pipeline. |
| CN05.AR01/AR02 | Policy | Kubernetes restricted pod security standard initiative in `Deny` mode, with no added capabilities allowed and `ALL` capabilities required to be dropped. |
| CN06.AR01 | K8s | Managed namespaces with `DenyAll` ingress and egress, enforced by Cilium. |
| CN06.AR02 | Residual | Application teams add explicit allow policies with stable selectors. |
| CN07.AR01 | TF | Private Key Vault KMS for Kubernetes secrets, CMK disk encryption, workload identity for delivery. |
| CN07.AR02 | Residual | Workload `Role` definitions must name the secrets they read. |
| CN08.AR01 | TF | `check "approved_addons_only"` compares the enabled add-ons with `var.approved_addons`. |
| CN09.AR01–AR03 | TF | Standard tier, `patch` and `NodeImage` upgrade channels, weekly maintenance windows, AKS-managed add-ons only. |
| CN10.AR01/AR02 | Residual | Storage-class and volume re-use policy are not configured by the example. |
| CN11.AR01 | Policy | Deny-mode assignments cover every non-system namespace; AKS manages system-namespace exclusions. |
| CN11.AR02 | TF | Policy changes need Azure policy permissions, are logged and raise the activity log alert. |
| CN11.AR03 | Residual | Gatekeeper webhook failure behavior is managed by the Azure Policy add-on. |
| CN12.AR01 | TF | AKS-managed kubelet authentication and authorization; anonymous access is disabled by the platform. |
| CN12.AR02 | TF | `ssh_access = "Disabled"`, no node public IPs. |
| CN12.AR03 | K8s | Default-deny egress blocks the instance metadata endpoint from workload namespaces. |
| CN13.AR01 | Policy | Every container must declare limits within `container_cpu_limit` and `container_memory_limit`. |
| CN13.AR02 | K8s | Namespace CPU and memory quotas. Storage and object-count quotas need an additional `ResourceQuota`. |
| CN13.AR03 | TF | Cluster autoscaler with an explicit `max_count`. |
| CN14.AR01 | TF | Diagnostic settings (all log groups), Container Insights and Defender to Log Analytics. |
| CN14.AR02 | TF | Separate workspace; no cluster, kubelet or workload identity is granted access to it. |
| CN14.AR03 | TF | Activity log alert for ARM changes and a KQL alert for Kubernetes RBAC, webhook and network policy changes. |
| CN15.AR01 | TF | Required `owner`, `environment` and `data-classification` tags; namespace labels and annotations. |
| CN15.AR02 | TF | Node resource group `ReadOnly` lockdown; metadata changes raise the activity log alert. |
| CN16.AR01/AR02 | TF | Managed Entra ID authentication; local accounts disabled. |
| CN17.AR01/AR02 | TF | Distinct control-plane, kubelet and workload identities; grants scoped to subnets, zone, identity and keys. |
| CN18.AR01/AR02 | TF | AKS-supplied Ubuntu images with Secure Boot and vTPM. |

## Prerequisites

- Permission to create resources and role assignments in the target subscription or resource group
  (for example Owner, or Contributor plus Role Based Access Control Administrator).
- The `Microsoft.Compute/EncryptionAtHost` feature registered on the subscription, and the
  `Microsoft.ContainerService`, `Microsoft.KeyVault`, `Microsoft.Network`, `Microsoft.ContainerRegistry`,
  `Microsoft.OperationalInsights`, `Microsoft.Insights` and `Microsoft.PolicyInsights` providers registered.
- A region that supports zones 1–3, Trusted Launch, encryption at host and `Standard_D4s_v5`.
- A Defender for Containers plan if Defender findings are required (CN04.AR03, CN14).

## Deploying

The Key Vault keys are created through the vault's private endpoint, so Terraform must run from a
host that can reach the runner VNet. This is the reason the example is excluded from automated E2E.

```powershell
terraform -chdir=examples/finos-ccc init
# 1. Create the resource group, VNets and NSGs.
terraform -chdir=examples/finos-ccc apply -target=module.virtual_networks
# 2. Place a self-hosted runner or jump host in the `runner_subnet_id` output (or connect to the
#    runner VNet through VPN or peering), then run the full deployment from there.
terraform -chdir=examples/finos-ccc apply
# 3. Check idempotency: exit code 0 means no changes.
terraform -chdir=examples/finos-ccc plan -detailed-exitcode
```

Without explicit `cluster_role_assignments`, the deploying identity receives
`Azure Kubernetes Service RBAC Cluster Admin`. Supply group-based, narrower roles for anything
beyond a demonstration. The API server is private and Run Command is disabled, so `kubectl` access
also requires a host in, or connected to, the cluster VNet.

## Reusing existing resources

Every prerequisite is created by default. Supply existing IDs to reuse them instead; nothing is
imported, and existing-to-existing role assignments stay with their owner.

| Input | Behavior when null |
| --- | --- |
| `resource_group_id` | Create a resource group. |
| `subnet_id`, `api_server_subnet_id`, `key_vault_private_endpoint_subnet_id`, `container_registry_private_endpoint_subnet_id` | Supply all four or none. When null, create the cluster and runner VNets. |
| `control_plane_identity_id`, `kubelet_identity_id` | Create distinct user-assigned identities. |
| `private_dns_zone_id` | Create `ccc-<suffix>.private.<location>.azmk8s.io` linked to the cluster VNet. |
| `key_vault_resource_id`, `key_vault_key_id` | Create a private, RBAC, purge-protected vault and an RSA-3072 KMS key. `key_vault_key_id` is a versioned HTTPS key URL. |
| `disk_encryption_set_id` | Create a separate disk key and a system-assigned DES. |
| `key_vault_private_dns_zone_id`, `container_registry_private_dns_zone_id` | Create the `privatelink` zones. Do not link the vault zone to the cluster VNet; AKS private KMS links its own. |

Grants are created only for a new principal or target. When the deployment creates the vault, the
deployer receives Key Vault Crypto Officer on that vault so it can create the keys. On a reused vault
the deployer must already hold that role, and the vault must use RBAC (and purge protection when a
DES is created).

## Key lifecycle

Legacy `azure_key_vault_kms` is used. Automatic key rotation and expiry are not configured; rotate
keys with the documented legacy KMS procedure. Destroy soft-deletes keys managed by this example
(including keys created in a reused vault). Purge-on-destroy is disabled, and a created vault is
retained under its 90-day purge protection. Never delete a key while a cluster still needs it.
