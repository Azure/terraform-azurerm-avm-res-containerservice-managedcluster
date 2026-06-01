<!-- markdownlint-disable-next-line MD041 -->
## Post-deployment steps

After Terraform completes, enable the ALB Controller managed add-on and configure Gateway API resources:

```bash
# 1. Enable the ALB Controller add-on on the AKS cluster
az aks update -g <resource_group_name> -n <aks_cluster_name> --enable-alb-controller

# 2. Verify ALB Controller pods are running
az aks command invoke -g <resource_group_name> -n <aks_cluster_name> \
  --command "kubectl get pods -n alb-system"

# 3. Apply Kubernetes Gateway API resources (GatewayClass, Gateway, HTTPRoute)
# See: https://learn.microsoft.com/azure/application-gateway/for-containers/quickstart-create-application-gateway-for-containers-byo-deployment
```

For a consumer with an existing hub-spoke network, replace the inline virtual network and subnet resources with references to existing subnet IDs.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
