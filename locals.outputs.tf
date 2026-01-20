locals {
  kubeconfig_admin = length(azapi_resource_action.this_admin_kubeconfig) == 1 ? base64decode(azapi_resource_action.this_admin_kubeconfig[0].output.kubeconfigs[0].value) : null
  kubeconfig_user  = !local.is_automatic ? base64decode(azapi_resource_action.this_user_kubeconfig[0].output.kubeconfigs[0].value) : null
}
