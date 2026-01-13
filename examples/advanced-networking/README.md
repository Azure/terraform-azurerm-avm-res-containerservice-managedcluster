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

<!-- markdownlint-disable-next-line MD041 -->

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
