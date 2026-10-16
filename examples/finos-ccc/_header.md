# FINOS CCC-informed private AKS cluster

This manual example deploys a **new** AKS cluster through the module in this
repository (`source = "../.."`), using an existing resource group and network.
Security settings are fixed in `main.tf`; inputs select the environment, not
switches that weaken the illustrated baseline. By default it creates separate
control-plane/kubelet identities, an API private DNS zone and VNet link, a private
Key Vault, separate KMS/disk keys, a disk encryption set (DES) and prerequisite
role assignments. Supplying existing IDs selects reuse instead; nothing is imported.
All prerequisite creation uses pinned, published AVM modules, including the runner's
vault private endpoint and DNS integration. AzAPI data sources only inspect existing
prerequisites or read the new DES principal ID. It does not deploy Kubernetes policies.

The advanced AKS `ignore_body_changes` interface permits only `tags`. Published
prerequisite modules own their API versions, retries, timeouts and lifecycle behavior;
the example's corresponding inputs do not override those modules.

**Contribution exception:** unlike the self-contained examples described in
`examples/README.md`, this scenario still requires approved existing subnets,
UDR/firewall egress, a resource group and Entra administrator groups.
VNet/subnet/egress creation is intentionally out of scope; private endpoint and DNS
integration are included. It is excluded from automated E2E discovery
using `.e2eignore`. Acceptance of this manual scenario, its required-input deviation
and its AzureRM-backed AVM dependencies needs module-maintainer review. These
published dependencies require AzureRM even though the parent AKS module uses AzAPI.
This is an explicitly chosen example-level deviation from the repository's
AzAPI-only provider guidance, not a claim of satisfying the narrow unsupported-API
exception. No direct AzureRM resources are authored in this example.
Exclusion is not evidence that deployment or idempotency checks passed.

### Published prerequisite modules

| Prerequisite | Registry module | Version |
| --- | --- | --- |
| User-assigned identities | `Azure/avm-res-managedidentity-userassignedidentity/azurerm` | `0.5.3` |
| Private DNS zones and VNet links | `Azure/avm-res-network-privatednszone/azurerm` (including its VNet-link submodule) | `0.5.0` |
| Key Vault and keys | `Azure/avm-res-keyvault-vault/azurerm` and `//modules/key` | `0.12.0` |
| Disk encryption set | `Azure/avm-res-compute-diskencryptionset/azurerm` | `0.1.1` |
| Prerequisite grants | `Azure/avm-res-authorization-roleassignment/azurerm` | `0.3.1` |
| Runner vault private endpoint | `Azure/avm-res-network-privateendpoint/azurerm` | `0.2.0` |

## Configuration illustrated

- Private API server, no public private-cluster FQDN, API-server VNet integration.
- Separate created or reused control-plane and kubelet user-assigned identities.
- Kubernetes RBAC with managed Entra authentication and supplied administrator groups.
- OIDC issuer and workload identity enabled.
- Customer-managed node-disk encryption and private Key Vault Kubernetes KMS.
- Two Ubuntu `Standard_D4s_v5` nodes, zones 1–3, Managed OS disks, no public node IPs.
- Azure CNI Overlay with Cilium, standard load balancer and user-defined routing.
- Fixed pod CIDR `172.18.0.0/16`, maximum 30 Pods per node and Base/Free test SKU.
- Azure Policy add-on and module telemetry disabled.

This preserves the supplied AKS configuration rather than silently adding stronger
security settings. Local accounts, Run Command, SSH, Secure Boot/vTPM, explicit
update channels, diagnostics and security alerts are **not** enforced here.
Free-tier/test sizing is not a production capacity or availability recommendation.

## Created prerequisites and reuse

Omit the optional inputs below (or set them to `null`) to create the corresponding
prerequisites. Supply an existing ARM ID to reuse it; `key_vault_key_id` is the
exception: it is a **versioned HTTPS key URL**, not an ARM ID.

| Optional input | Behavior when omitted |
| --- | --- |
| `control_plane_identity_id` | Create a user-assigned control-plane identity. |
| `kubelet_identity_id` | Create a distinct user-assigned kubelet identity. |
| `private_dns_zone_id` | Create `ccc-<suffix>.private.<location>.azmk8s.io` and link it to the existing cluster VNet. |
| `key_vault_resource_id` | Create a Standard RBAC vault with public access disabled, deny-by-default networking, soft delete and 90-day purge protection. |
| `key_vault_key_id` | Create a non-exportable RSA-3072 KMS key with encrypt/decrypt operations in the selected vault. |
| `disk_encryption_set_id` | Create a separate RSA-3072 wrap/unwrap disk key and a system-assigned DES in the cluster region. |

An existing KMS key URL **must** be paired with its existing vault ARM ID. A reused
DES retains its own key/vault; it need not use the KMS vault. Creating keys or new
identity grants in an existing vault requires RBAC mode. Creating a DES additionally
requires a purge-protected vault in the cluster region. The example checks these
properties without changing the existing vault's configuration.

Names use a random suffix retained in Terraform state. A new API DNS zone uses the
[`private.<region>.azmk8s.io` family documented for API-server VNet integration](https://learn.microsoft.com/azure/aks/private-clusters#configuration-options-for-private-dns).
Existing zone IDs, including cross-subscription IDs, are passed through unchanged;
their links and DNS forwarding must already work. Register `Microsoft.ContainerService`
in both subscriptions when using cross-subscription DNS. Created zones are linked
only to the cluster VNet; private administration from other networks needs separate
DNS resolution and approved connectivity.

The control-plane identity receives Network Contributor on the existing VNet only
when that identity is new. Grants on DNS, the kubelet identity, the KMS key, KMS vault
and DES are created only when the principal or target is new. The DES identity gets
Key Vault Crypto Service Encryption User on its **disk key**; the control plane gets
Key Vault Crypto User on its **KMS key**. Key Vault Contributor on the KMS vault allows
AKS to create its private link. The DES module's built-in vault-wide grant is disabled
in favor of the separate key-scoped grant. Full prerequisite reuse creates **no**
prerequisite role assignments, runner endpoint or vault DNS resources: existing-to-existing
grants remain externally owned, preventing duplicate assignment conflicts. AVM owns
the assignment identifiers; the previous direct-resource GUID scheme is not retained.

### Key creation, private access and lifecycle

The AVM key submodule manages key creation, refresh, updates and deletion through
the Key Vault **data plane**. The runner must resolve the vault hostname to its private
endpoint and reach TCP 443 during plan, apply and destroy. It must already hold
effective Key Vault Crypto Officer (or equivalent key-management) permissions. For a
new vault, arrange an inherited grant on its resource group/subscription before
deployment; this example does not grant its caller extra permissions. Public vault
access is never temporarily enabled. Key outputs passed to AKS/DES are versioned
HTTPS URLs; role assignments use versionless ARM key IDs.

The following networking inputs have **no defaults** and must be supplied explicitly,
even for full reuse:

- `key_vault_private_endpoint_subnet_id`: existing dedicated, non-delegated endpoint
  subnet, distinct from the node/API subnets. No subnet or routing is created.
- `key_vault_private_dns_zone_id`: existing `privatelink.vaultcore.azure.net` zone ARM
  ID, or explicit `null` to create the zone through AVM. Reuse a shared zone rather
  than creating a duplicate namespace in an already-linked VNet.
- `key_vault_dns_virtual_network_links`: map of **new** link names to existing VNet
  IDs. Include the runner VNet or a DNS-forwarding hub for a new zone. With a reused
  zone, supply only links that do not already exist, or `{}` if resolution is already
  established. Existing links are never imported. Custom DNS forwarding, peering,
  routes and NSG rules remain external; VNet links alone do not prove reachability.

When either key is created, a dedicated runner private endpoint and DNS zone group
are created for the selected new or reused vault. New DNS zones contain the supplied
links; reused zones receive only explicitly requested new links. With full key/DES
reuse, these inputs remain required but no runner endpoint or vault DNS resources
are created. A newly created endpoint must be approved before key operations can
succeed; the caller needs private-endpoint connection approval permissions.

For [private KMS](https://learn.microsoft.com/azure/aks/use-kms-etcd-encryption), AKS
creates its own private endpoint and DNS link in the node resource group, separately
from the runner endpoint. NSGs/routes must allow TCP 443 from the API subnet to the
AKS endpoint. The created vault's `AzureServices` bypass allows
[trusted Azure Disk Storage/DES access even with public network access disabled](https://learn.microsoft.com/azure/key-vault/general/overview-vnet-service-endpoints#trusted-services);
it is not public or anonymous access and the DES identity still needs its key grant.
Reused vaults must already have the corresponding private connectivity/trusted-service
settings; those settings are not mutated by this example.

Legacy `azure_key_vault_kms` is intentionally preserved from the working configuration.
Microsoft recommends the newer KMS experience for Kubernetes 1.33+; migration is not
performed here. Automatic key rotation/expiry is not configured. Keep keys available
for decryption and perform the documented legacy KMS rotation and secret rewrite
procedure separately. A no-change Terraform plan is not key-lifecycle evidence.

Destroy removes the cluster, newly managed prerequisites and this example's grants,
and **soft-deletes keys managed by AVM, including keys created in a reused vault**.
Supplied existing keys are not managed or deleted. Vault/key purge-on-destroy is
disabled in the AzureRM provider; deleting a created vault retains it under its
90-day purge-protection policy. Private endpoint/DNS access remains until the managed
keys are deleted. Do not destroy encryption keys while any consumer still needs
them. This example targets fresh state, not migration from the former direct AzAPI
resources. Do not apply it over existing state without a separately reviewed import/
state-migration plan; module addresses, provider ownership and key lifecycle differ.

## FINOS CCC scope

Annotations reference the [Kubernetes catalog](https://github.com/finos/common-cloud-controls/blob/443b0a2b27e2d9bdfe0abb2eb65a1865e5dbe416/catalogs/orchestration/k8s/controls.yaml)
and its imported Core controls at the same revision. The catalog has no populated
release version. `partial` and `supporting` are configuration descriptions, not
official CCC assessment verdicts. This example is **not a CCC attestation or CFI report**.

| Controls | Configuration intent | Required outside this example |
| --- | --- | --- |
| CCC.K8S.CN01 / CCC.Core.CN05 | Private API | Approved private perimeter, effective access restrictions and negative reachability tests. |
| CCC.K8S.CN02 / CN16 | Managed Entra and RBAC | Narrow workload Roles/Bindings, governed human access, local-account disabling and revocation tests. |
| CCC.K8S.CN03 / CN17 | Workload federation mechanisms and separate infrastructure identities | Dedicated federated credentials, static-key prevention and minimal effective grants. |
| CCC.K8S.CN06 | Cilium and UDR | Namespace default-deny/approved-allow policies and dataplane connectivity tests. |
| CCC.K8S.CN07 / CCC.Core.CN02 | KMS and node DES | Secret authorization/delivery, key lifecycle and workload/PV encryption evidence. |
| CCC.K8S.CN08 / CN09 | Explicit add-on choice, supplied Kubernetes version | Approved add-on inventory, support/patch/compatibility evidence. |
| CCC.K8S.CN12 / CN18 | No public node IPs and service-managed Ubuntu image | Kubelet/SSH/IMDS restrictions and boot-integrity evidence. |
| CCC.K8S.CN15 / CCC.Core.CN06 | Supplied tags and region | Approved values/locations, protected metadata, workload labels and evidence. |

**Not implemented:** CN04 image signature/provenance/vulnerability admission,
CN05 restricted pod security, CN10 PVC ownership/access policy, CN11 mandatory
admission enforcement, CN13 workload limits/quotas/autoscaler maxima, CN14 external
audit/monitoring/alerts, and remaining imported Core requirements. Enabling Cilium,
OIDC or RBAC alone does not close those gaps. All live requirement results remain
unassessed until separately tested.

## Prerequisites

Use dedicated test state and approved, reusable prerequisites. Do not copy state
from another deployment or use this example to adopt or modify an existing cluster.
The default cluster name has a random suffix stored in state; an explicit `name`
must also be new. Keep state private: the module retrieves sensitive kubeconfig.

- An authenticated deployment principal with permission to create AKS, identities,
  DNS, vault/keys and DES in the existing resource group, list AKS credentials,
  create the VNet link and assign roles at every affected scope (including shared
  VNet/identity/key scopes). Creating keys also requires already-propagated data-plane
  key-management permissions and private connectivity as described above. No
  deployment-principal Crypto Officer grant is created.
  Register the required Azure resource providers and confirm resource quota.
- Distinct existing node/API subnets in the **same** VNet. The API subnet must be
  delegated to `Microsoft.ContainerService/managedClusters`, /28 or larger. Existing
  NSGs, routes and DNS forwarding must support private KMS and AKS dependencies.
  The node subnet must already have UDR/firewall egress. Supply an additional
  non-delegated private-endpoint subnet and explicit vault DNS inputs. No VNet,
  subnet or outbound-routing settings are created or changed.
- For reused identities/targets, verify existing-to-existing grants: control-plane
  network and private DNS access, Managed Identity Operator on the kubelet identity,
  DES read access, KMS encrypt/decrypt and private-link setup. A reused DES needs its
  own identity's key access and compatible key/vault. Grants may take time to
  propagate; AKS `retry`/`timeouts` do not configure prerequisite-module retries.
- Governed Entra **group** object IDs, not user object IDs.
- A region supporting the selected Kubernetes version, VM size and zones 1–3.
  Confirm no overlap between node/API/connected networks, service CIDR and fixed
  pod CIDR `172.18.0.0/16`; `dns_service_ip` must be within `service_cidr`.

## Manual usage

From the repository root, create a private, untracked
`examples/finos-ccc/terraform.tfvars.json`. Replace every placeholder with approved
values; the template below is not deployable as written. `name` may be omitted.
This minimal template creates all six requested prerequisites (plus a separate
disk key, runner private endpoint, vault DNS zone/links and necessary grants).

```json
{
  "location": "<SUPPORTED_REGION>",
  "resource_group_id": "<EXISTING_RESOURCE_GROUP_ARM_ID>",
  "kubernetes_version": "<SUPPORTED_KUBERNETES_VERSION>",
  "cluster_admin_group_object_ids": ["<ENTRA_GROUP_OBJECT_ID>"],
  "subnet_id": "<NODE_SUBNET_ARM_ID>",
  "api_server_subnet_id": "<DELEGATED_API_SUBNET_ARM_ID>",
  "key_vault_private_endpoint_subnet_id": "<PRIVATE_ENDPOINT_SUBNET_ARM_ID>",
  "key_vault_private_dns_zone_id": null,
  "key_vault_dns_virtual_network_links": {
    "runner-vnet": "<RUNNER_OR_DNS_HUB_VNET_ARM_ID>"
  },
  "service_cidr": "<NON_OVERLAPPING_SERVICE_CIDR>",
  "dns_service_ip": "<DNS_IP_WITHIN_SERVICE_CIDR>",
  "tags": {"owner": "<APPROVED_OWNER>", "environment": "test"}
}
```

To reuse the existing approved prerequisites, add these properties to the same
JSON object. Partial reuse is also supported, subject to the ownership rules above.
Never publish corporate resource IDs, internal tags, credentials or Terraform state.

```json
{
  "control_plane_identity_id": "<CONTROL_PLANE_IDENTITY_ARM_ID>",
  "kubelet_identity_id": "<DISTINCT_KUBELET_IDENTITY_ARM_ID>",
  "private_dns_zone_id": "<AKS_PRIVATE_DNS_ZONE_ARM_ID>",
  "disk_encryption_set_id": "<DISK_ENCRYPTION_SET_ARM_ID>",
  "key_vault_key_id": "<VERSIONED_KMS_KEY_URL>",
  "key_vault_resource_id": "<KMS_VAULT_ARM_ID>"
}
```

```powershell
terraform -chdir=examples/finos-ccc init
terraform -chdir=examples/finos-ccc validate
terraform -chdir=examples/finos-ccc plan -out=finos-ccc.tfplan
# Stop and review the plan, costs, prerequisite reuse and new cluster name.
# Apply only after explicit deployment approval.
terraform -chdir=examples/finos-ccc apply finos-ccc.tfplan
# Check deployment idempotency; the plan must report no changes.
terraform -chdir=examples/finos-ccc plan -detailed-exitcode
```

An idempotency exit code of 0 means no changes; 2 means drift and 1 means an error.
Neither deployment nor idempotency has been established merely by publishing this
example. Cleanup must be separately approved, respect retained keys/vaults described
above and never delete shared prerequisites. Implementation is split between
`main.tf`, `main.prerequisites.tf` and `locals.tf`; outputs expose the selected IDs.
