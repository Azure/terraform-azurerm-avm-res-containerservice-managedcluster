# Upgrade Guide

## 0.3.0 to 0.4.0

### Breaking Changes

- **`resource_group_name`** has been removed. Use **`parent_id`** instead, which should be the full resource ID of the resource group.
- **`sku_tier`** has been removed. Use **`sku`** object instead.

  ```hcl
  # Old
  sku_tier = "Standard"

  # New
  sku = {
    name = "Base" # or "Standard", "Automatic"
    tier = "Standard" # or "Free"
  }
  ```

- **`service_principal`** has been removed.
- **`kubelet_identity`** has been removed.
- **`http_application_routing_enabled`** has been removed.
- **`aci_connector_linux_subnet_name`** has been removed.
- **`edge_zone`** has been removed.
- **`maintenance_window_node_os`** has been removed.
- **`open_service_mesh_enabled`** has been removed.
- **`web_app_routing_dns_zone_ids`** type changed from `map(list(string))` to `list(string)`.

### Variable Renames and Moves

- **`role_based_access_control_enabled`** renamed to **`enable_role_based_access_control`**.
- **`local_account_disabled`** replaced by **`disable_local_accounts`**.
- **`run_command_enabled`** moved to **`api_server_access_profile.run_command_enabled`**.
- **`private_cluster_enabled`** moved to **`api_server_access_profile.enable_private_cluster`**.
- **`private_cluster_public_fqdn_enabled`** moved to **`api_server_access_profile.enable_private_cluster_public_fqdn`**.
- **`private_dns_zone_id`** moved to **`api_server_access_profile.private_dns_zone_id`**.
- **`api_server_access_profile.virtual_network_integration_enabled`** renamed to **`api_server_access_profile.enable_vnet_integration`**.

### Service Mesh Profile Changes

The `service_mesh_profile` variable structure has changed to support Istio configuration more comprehensively.

```hcl
# Old
service_mesh_profile = {
  mode = "Istio"
  internal_ingress_gateway_enabled = true
  # ...
}

# New
service_mesh_profile = {
  mode = "Istio"
  istio = {
    components = {
      ingressGateways = {
        enabled = true
        mode    = "Internal"
      }
    }
    # ...
  }
}
```

### New Features

- **`advanced_networking`**: Added support for advanced networking features (observability, security).
- **Observability**: Added `alert_email`, `onboard_alerts`, `onboard_monitoring`, `log_analytics_workspace_id`, `prometheus_workspace_id`.
- **`windows_profile_password_version`**: Added support for specifying password version.
- **`network_profile.network_plugin`**: Now optional (defaults to "azure").
