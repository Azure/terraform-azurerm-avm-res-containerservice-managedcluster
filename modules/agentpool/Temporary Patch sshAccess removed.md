## Temporary Patch: sshAccess removed

This fork removes/comments out the `sshAccess` field from the AKS request payload.

### Reason

The AKS API version `Microsoft.ContainerService/managedClusters@2025-10-01` rejects the `sshAccess` field during create/update operations with: `UnmarshalError: unknown field "sshAccess"` 

Even when not explicitly configured, the upstream AVM module serializes this field in the agent pool `securityProfile`, causing deployment failures.

### Impact

- Does NOT affect cluster functionality
- SSH access to nodes is still handled internally by AKS
- Recommended access methods:
  - `kubectl debug`
  - Azure Entra ID (AAD-based access)

### Status

Temporary workaround until upstream fix is released.

### TODO

Remove this patch once:
- AVM module stops sending `sshAccess`, OR
- AKS API accepts the field again