# Advanced Networking Example

This example deploys an AKS cluster with Advanced Networking features enabled using the Azure CNI with Cilium data plane.

## Advanced Networking Features

Advanced Networking provides enhanced network capabilities for AKS clusters:

- **Observability**: Enables enhanced network observability features powered by Cilium Hubble for monitoring and troubleshooting network traffic.
- **Security**: Enables advanced network security features including enhanced network policies.

## Prerequisites

- Advanced Networking requires `network_plugin = "azure"` and `network_data_plane = "cilium"`
- The `network_policy` should be set to `cilium` for full feature support
- `network_plugin_mode = "overlay"` is recommended for better IP address management

## Configuration

```hcl
network_profile = {
  network_plugin      = "azure"
  network_data_plane  = "cilium"
  network_plugin_mode = "overlay"
  network_policy      = "cilium"
}

advanced_networking = {
  enabled = true
  observability = {
    enabled = true
  }
  security = {
    enabled = true
  }
}
```
