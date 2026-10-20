# CCC.K8S.CN03.AR01: a dedicated cloud identity per workload, federated to its Kubernetes
# service account so the workload receives short-lived tokens instead of stored keys.
# Grant each identity only the Azure roles its workload needs (none are granted here).
module "workload_identities" {
  source    = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version   = "0.5.3"
  providers = { modtm = modtm }
  for_each  = var.workload_namespaces

  location            = var.location
  name                = "id-ccc-workload-${each.key}-${random_string.name_suffix.result}"
  resource_group_name = local.resource_group_name
  enable_telemetry    = var.enable_telemetry
  federated_identity_credentials = {
    service_account = {
      name     = "fic-${each.key}"
      audience = ["api://AzureADTokenExchange"]
      issuer   = module.aks.oidc_issuer_profile_issuer_url
      subject  = "system:serviceaccount:${each.key}:${each.value.service_account_name}"
    }
  }
  tags = var.tags
}
