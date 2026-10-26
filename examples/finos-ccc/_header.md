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
| Cluster VNet and subnets | `Azure/avm-res-network-virtualnetwork/azurerm` | CN01, Core.CN05 |
| One NSG per subnet | `Azure/avm-res-network-networksecuritygroup/azurerm` | CN01, Core.CN05 |
| Control-plane, kubelet and workload identities | `Azure/avm-res-managedidentity-userassignedidentity/azurerm` | CN03, CN17 |
| API server and registry private DNS | `Azure/avm-res-network-privatednszone/azurerm` | CN01 |
| Private Key Vault | `Azure/avm-res-keyvault-vault/azurerm` | CN07, Core.CN02 |
| KMS and disk keys, created through Azure Resource Manager | `azapi_resource_action` (`Microsoft.KeyVault/vaults/keys`) | CN07, Core.CN02 |
| Disk encryption set | `Azure/avm-res-compute-diskencryptionset/azurerm` | Core.CN02 |
| Least-privilege infrastructure grants | `Azure/avm-res-authorization-roleassignment/azurerm` | CN17 |
| Private approved registry | `Azure/avm-res-containerregistry-registry/azurerm` | CN04 |
| Azure Policy for Kubernetes assignments | `Azure/avm-ptn-policyassignment/azurerm` | CN04, CN05, CN11, CN13 |
| Log Analytics workspace | `Azure/avm-res-operationalinsights-workspace/azurerm` | CN14, Core.CN04 |
| Action group for security alerts | `Azure/avm-res-insights-actiongroup/azurerm` | CN14 |
| Activity log alert | `Azure/avm-res-insights-activitylogalert/azurerm` | CN14, CN11, CN15 |
| Kubernetes audit log alert | `azapi_resource` (`avm-res-insights-scheduledqueryrule` is only Proposed) | CN14 |

## CCC control mapping

Legend: **TF** enforced by Terraform-managed Azure configuration, **Policy** enforced at
admission by Azure Policy for Kubernetes, **K8s** enforced by Kubernetes objects created by the
example, **Partial** only part of the AR is enforced (the rest is noted), **Residual** requires an
operational process or is a platform limitation.

| AR | Enforcement | How |
| --- | --- | --- |
| CN01.AR01 | TF | Private cluster with API-server VNet integration; NSGs on every subnet. |
| CN01.AR02 | TF | `public_network_access = "Disabled"`, no public FQDN, Run Command disabled. |
| CN02.AR01 | TF | Entra ID with Azure RBAC for Kubernetes. No Kubernetes role is granted by default, not even to the deployer; grant scoped roles with `cluster_role_assignments`. Admin groups are break-glass only. |
| CN02.AR02 | Residual | Only built-in AKS RBAC roles are granted. Workload `Role` definitions belong to application teams and need review in CI. |
| CN03.AR01 | TF | OIDC issuer, workload identity and one federated identity per workload namespace service account. Workloads need the DNS and HTTPS egress policy below to exchange tokens. |
| CN03.AR02 | Residual | Scan manifests, Secrets and ConfigMaps for static credentials in CI. |
| CN04.AR01 | Policy | Allowed images: the private registry only, pinned by `@sha256` digest. |
| CN04.AR02 | Residual | Sign images in the build pipeline. AKS Image Integrity is preview and audit-only, so it is not enabled. |
| CN04.AR03 | Residual | Defender for Containers reports vulnerabilities; gate releases on them in the pipeline. |
| CN05.AR01/AR02 | Policy | Kubernetes restricted pod security standard initiative in `Deny` mode, with no added capabilities allowed and `ALL` capabilities required to be dropped. |
| CN06.AR01 | K8s | Managed namespaces with `DenyAll` ingress and egress, enforced by Cilium. |
| CN06.AR02 | Residual | Application teams add explicit allow policies with stable selectors (see the sample below). |
| CN07.AR01 | Partial | Kubernetes secrets are encrypted in etcd with a private Key Vault KMS key and node disks with a customer-managed key. No secret delivery path to workloads (for example the Secrets Store CSI driver) is configured. |
| CN07.AR02 | Residual | Workload `Role` definitions must name the secrets they read. |
| CN08.AR01 | TF | Plan fails before the cluster is created if the example configures an add-on outside `approved_addons`. After apply, the cluster is read back and apply and later plans fail if AKS reports any other add-on or managed feature enabled, including AKS defaults. Storage drivers are set explicitly (disk CSI only). The default allowlist includes `extension_manager`, which AKS enables to run Container Insights as a core extension. |
| CN09.AR01–AR03 | TF | Standard tier, `patch` and `NodeImage` upgrade channels, weekly maintenance windows, AKS-managed add-ons only. |
| CN10.AR01/AR02 | Residual | Storage-class and volume re-use policy are not configured by the example. |
| CN11.AR01 | Policy | Deny-mode assignments cover every non-system namespace; AKS manages system-namespace exclusions. |
| CN11.AR02 | TF | Policy changes need Azure policy permissions, are logged and raise the activity log alert. |
| CN11.AR03 | Residual | Gatekeeper webhook failure behavior is managed by the Azure Policy add-on. |
| CN12.AR01 | TF | AKS-managed kubelet authentication and authorization; anonymous access is disabled by the platform. |
| CN12.AR02 | TF | `ssh_access = "Disabled"`, no node public IPs. |
| CN12.AR03 | K8s | Default-deny egress blocks the instance metadata endpoint from workload namespaces; the sample allow policy keeps it blocked. |
| CN13.AR01 | Policy | Every container must declare limits within `container_cpu_limit` and `container_memory_limit`. |
| CN13.AR02 | K8s | Namespace CPU and memory quotas. Storage and object-count quotas need an additional `ResourceQuota`. |
| CN13.AR03 | TF | Cluster autoscaler with an explicit `max_count`. |
| CN14.AR01 | TF | Diagnostic settings (all log groups), Container Insights and Defender to Log Analytics. |
| CN14.AR02 | TF | Separate workspace; no cluster, kubelet or workload identity is granted access to it. |
| CN14.AR03 | TF | Activity log alert for ARM changes and a KQL alert for Kubernetes RBAC, webhook and network policy changes. Both notify an action group: the subscription's Owners by email, plus `alert_email_addresses`. |
| CN15.AR01 | TF | Required `owner`, `environment` and `data-classification` tags; namespace labels and annotations. |
| CN15.AR02 | TF | Node resource group `ReadOnly` lockdown; metadata changes raise the activity log alert. |
| CN16.AR01/AR02 | TF | Managed Entra ID authentication; local accounts disabled. |
| CN17.AR01 | TF | Distinct control-plane, kubelet and workload identities. |
| CN17.AR02 | TF | Grants are scoped to the subnets, API DNS zone, kubelet identity and individual keys, with two documented exceptions AKS requires: **Key Vault Contributor on the vault** (private KMS creates its own private endpoint to the vault) and **Reader on the disk encryption set**. No human identity holds a Key Vault data-plane role. |
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

Every input has a default, and the deployment runs from any host with Azure access. The Key Vault
keeps public network access disabled: its keys are created through Azure Resource Manager, not the
vault's data plane, so no runner, vault private endpoint or deployer Key Vault role is needed.

```powershell
terraform -chdir=examples/finos-ccc init
terraform -chdir=examples/finos-ccc apply
```

- **Telemetry and idempotency.** AVM telemetry is enabled by default (`enable_telemetry = true`).
  Each AVM module's telemetry deployment records the apply time, so it shows as an in-place update
  on every plan. To check idempotency of the example's own resources, for example in a test
  deployment, use `-var enable_telemetry=false` for both the apply and
  `terraform plan -detailed-exitcode` (exit code 0 means no changes).
- **KMS key URL.** AKS accepts a versioned key URL on legacy KMS (the default here) and only a
  versionless one when it runs the cluster on its newer KMS experience (platform-managed keys,
  Kubernetes 1.33 or later). If the cluster create fails with
  `KeyId must not include a version when PMK is enabled`, set `kms_key_versionless = true`.
- **Cluster access.** No Kubernetes role is granted by default. Add your group to
  `cluster_role_assignments` (for example `Azure Kubernetes Service RBAC Writer`), or for
  break-glass add it to `cluster_admin_group_object_ids`. The API server is private and Run Command
  is disabled, so `kubectl` also requires a host in, or connected to, the cluster VNet.
- **Alerts** go to the subscription's Owners by email; add the security team with
  `alert_email_addresses`.

## Running a workload

Workload namespaces deny all ingress and egress, and Azure Policy admits only digest-pinned images
from the private registry that meet the restricted pod security standard and the CPU and memory
limits. Public access to the registry is disabled but trusted Azure services may write to it, so
import an image by digest. Read the digest from the source registry: commands that query the private
registry itself only work from inside the cluster VNet.

```bash
digest=$(curl -sI \
  -H "Accept: application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.index.v1+json" \
  https://mcr.microsoft.com/v2/azurelinux/busybox/manifests/1.36 \
  | tr -d '\r' | awk 'tolower($1)=="docker-content-digest:" {print $2}')
az acr import --name <registry> --source "mcr.microsoft.com/azurelinux/busybox@${digest}" --image busybox:1.36
echo "$digest"
```

Import copies the manifest unchanged, so the image keeps the same digest in the private registry.

Then apply, in the workload namespace (`workload-a` by default):

```yaml
# DNS to CoreDNS and HTTPS egress (Entra ID token exchange for workload identity, Azure APIs).
# The instance metadata endpoint stays blocked (CN12.AR03).
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-and-https-egress
  namespace: workload-a
spec:
  podSelector: {}
  policyTypes: ["Egress"]
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - { port: 53, protocol: UDP }
        - { port: 53, protocol: TCP }
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except: ["169.254.169.254/32"]
      ports:
        - { port: 443, protocol: TCP }
---
# The service account federated to the namespace's workload identity
# (output workload_identity_client_ids["workload-a"]).
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload
  namespace: workload-a
  annotations:
    azure.workload.identity/client-id: <workload identity client ID>
---
# The restricted initiative also requires pod-level fsGroup and supplementalGroups.
apiVersion: v1
kind: Pod
metadata:
  name: sample
  namespace: workload-a
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: workload
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    runAsGroup: 10001
    fsGroup: 10001
    supplementalGroups: [10001]
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: <registry>.azurecr.io/busybox@sha256:<digest>
      command: ["sleep", "86400"]
      resources:
        requests: { cpu: 100m, memory: 128Mi }
        limits: { cpu: 500m, memory: 512Mi }
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop: ["ALL"]
```

The sample runs as a non-root user on a read-only root filesystem. From a host that can reach the
private API server, show that DNS works and the instance metadata endpoint stays blocked:

```bash
kubectl -n workload-a exec sample -- nslookup login.microsoftonline.com
kubectl -n workload-a exec sample -- wget -q -T 5 -O- --header "Metadata: true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" || echo "IMDS blocked"
```

## Reusing existing resources

Every prerequisite is created by default. Supply existing IDs to reuse them instead; nothing is
imported, and existing-to-existing role assignments stay with their owner.

| Input | Behavior when null |
| --- | --- |
| `resource_group_id` | Create a resource group. |
| `subnet_id`, `api_server_subnet_id`, `container_registry_private_endpoint_subnet_id` | Supply all three or none. When null, create the cluster VNet. |
| `control_plane_identity_id`, `kubelet_identity_id` | Create distinct user-assigned identities. |
| `private_dns_zone_id` | Create `ccc-<suffix>.private.<location>.azmk8s.io` linked to the cluster VNet. |
| `key_vault_resource_id`, `key_vault_key_id` | Create a private, RBAC, purge-protected vault and an RSA-3072 KMS key. `key_vault_key_id` is an HTTPS key URL, versioned unless `kms_key_versionless` is true. |
| `disk_encryption_set_id` | Create a separate disk key and a system-assigned DES. |
| `container_registry_private_dns_zone_id` | Create the `privatelink.azurecr.io` zone. |

Grants are created only for a new principal or target. Keys created in a reused vault need
`Microsoft.KeyVault/vaults/keys/write` on it (for example Key Vault Contributor) for the deployer;
the vault must use RBAC (and purge protection when a DES is created).

## Key lifecycle

Legacy `azure_key_vault_kms` is used. Automatic key rotation and expiry are not configured; rotate
keys with the documented legacy KMS procedure. Azure Resource Manager cannot delete keys, so destroy
does not delete them: a created vault is deleted (soft-deleted and kept under its 90-day purge
protection) together with its keys, and keys created in a reused vault remain there. Purge-on-destroy
is disabled. Never delete a key while a cluster still needs it.
