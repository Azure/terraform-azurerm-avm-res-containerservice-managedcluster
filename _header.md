# terraform-azurerm-avm-res-containerservice-managedcluster

> Upgrading an existing deployment? Follow the [AzureRM interface migration guide](MIGRATION.md) before applying a new module version.

## Kubernetes version upgrades

Set `kubernetes_version` to a supported AKS upgrade target. The default agent pool
and additional agent pools wait for the control-plane version update to complete
before applying their changes. Agent pools inherit `kubernetes_version` unless an
explicit `orchestrator_version` is configured; explicit versions must remain
compatible with the control plane.
