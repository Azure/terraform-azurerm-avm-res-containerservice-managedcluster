## Temporary Patch: sshAccess removed from managedClusters PUT payload

This fork patches the upstream AVM module `terraform-azurerm-avm-res-containerservice-managedcluster` (v0.5.3) to fix `UnmarshalError: unknown field "sshAccess"` when creating/updating AKS clusters via `azapi_resource`.

### Root Cause

The AKS `managedClusters` PUT API (`@2025-10-01`) does **not** accept `sshAccess` inside `agentPoolProfiles[].securityProfile`. The field is only valid on the **separate** `managedClusters/agentPools` child resource, never in the nested `agentPoolProfiles` array of a cluster PUT request. This was not an issue with the older `azurerm` provider (v0.2.5) because it abstracted the payload. The newer `azapi`-based module sends raw JSON, exposing the mismatch.

Confirmed via API testing:
- `GET managedClusters?api-version=2026-01-01` returns `securityProfile: {enableSecureBoot, enableVTPM}` — no `sshAccess`
- `GET managedClusters?api-version=2024-01-01` returns `securityProfile: null` — field didn't exist yet
- `sshAccess` has **never** been part of `agentPoolProfiles` in any API version

### Impact

- Does NOT affect cluster functionality
- `enableSecureBoot` and `enableVTPM` are preserved in `agentPoolProfiles`
- SSH access to nodes is still handled internally by AKS via the separate agentpool resource
- `ignore_changes` on `body.properties.agentPoolProfiles` temporarily removed to allow state cleanup

---

## Modified Files (vs upstream v0.5.3, commit `45c6faa`)

### 1. `modules/agentpool/locals.tf`

**Line 132** — Commented out `sshAccess` from `securityProfile` in `resource_body`:
```
# Before:
sshAccess        = var.security_profile.ssh_access
# After:
//sshAccess        = var.security_profile.ssh_access
```

**Lines 160-171** — Added new local `resource_body_properties_no_security` that rebuilds `securityProfile` without `sshAccess` (keeps `enableSecureBoot` and `enableVTPM`):
```hcl
resource_body_properties_no_security = merge(
  { for k, v in local.resource_body.properties : k => v if k != "securityProfile" },
  local.resource_body.properties.securityProfile == null ? {} : {
    securityProfile = {
      for k, v in local.resource_body.properties.securityProfile : k => v if k != "sshAccess"
    }
  }
)
```

### 2. `modules/agentpool/outputs.tf`

**Lines 1-3** — `body_properties` output now uses the filtered local instead of the full `resource_body.properties`:
```
# Before:
value = var.output_data_only ? local.resource_body.properties : null
# After:
value = var.output_data_only ? local.resource_body_properties_no_security : null
```
Description updated to document that `securityProfile` is rebuilt without `sshAccess`.

### 3. `modules/agentpool/variables.tf`

**Line 585** — Commented out `ssh_access` from `security_profile` type definition:
```
# Before:
ssh_access         = optional(string)
# After:
//ssh_access         = optional(string)
```

**Line 593** — Description changed from active to disabled note:
```
# Before:
- `ssh_access` - SSH access method of an agent pool.
# After:
- (ssh_access - SSH access method of an agent pool - disabled: not supported in PUT requests)
```

**Lines 597-601** — Validation block for `ssh_access` commented out:
```
# Before:
validation {
  condition     = var.security_profile == null || var.security_profile.ssh_access == null || contains(["Disabled", "LocalUser"], var.security_profile.ssh_access)
  error_message = "security_profile.ssh_access must be one of: [\"Disabled\", \"LocalUser\"]."
}
# After:
//validation {
//  condition     = ...
//  error_message = ...
//}
```

### 4. `variables.tf`

**Line 477** — Commented out `ssh_access` from `default_agent_pool.security_profile` type:
```
# Before:
ssh_access         = optional(string)
# After:
//ssh_access         = optional(string)
```

### 5. `variables.agent_pool.tf`

**Line 130** — Commented out `ssh_access` from `agent_pools` map type:
```
# Before:
ssh_access         = optional(string)
# After:
//ssh_access         = optional(string)
```

**Line 229** — Description changed to disabled note:
```
# Before:
- `ssh_access` - SSH access method of an agent pool.
# After:
- (ssh_access - SSH access method of an agent pool - disabled: not supported in PUT requests)
```

### 6. `locals.agent_pool_profiles.tf`

**Lines 10-12** — Added comment explaining why `securityProfile` is handled separately:
```hcl
# securityProfile is excluded from agentPoolProfiles because the managedClusters API
# does not accept sshAccess (and other securityProfile fields) in PUT requests via agentPoolProfiles.
# securityProfile is managed separately via azapi_update_resource.default_agent_pool.
```

### 7. `main.tf`

**Line 57** — Removed `body.properties.agentPoolProfiles` from `ignore_changes` (temporary, to allow state cleanup):
```
# Before:
ignore_changes = [
  body.properties.kubernetesVersion,
  body.properties.agentPoolProfiles,
]
# After:
ignore_changes = [
  body.properties.kubernetesVersion,
]
```

---

### Status

Temporary workaround until upstream AVM module is fixed.

### TODO

Remove this patch once:
- Upstream AVM module strips `sshAccess` from `agentPoolProfiles`, OR
- AKS API accepts the field in `agentPoolProfiles` (unlikely based on API schema history)

After successful apply, restore `body.properties.agentPoolProfiles` to `ignore_changes` in `main.tf`.