# CCC.K8S.CN14 / CCC.Core.CN04 / CCC.Core.CN09: external audit and monitoring sink.
# CN14.AR02: no cluster, kubelet or workload identity is granted access to the workspace;
# grant read access to a dedicated security-operations group through Azure RBAC.
module "log_analytics" {
  source    = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version   = "0.5.1"
  providers = { modtm = modtm }

  location                                  = var.location
  name                                      = "law-ccc-${random_string.name_suffix.result}"
  resource_group_name                       = local.resource_group_name
  enable_telemetry                          = var.enable_telemetry
  log_analytics_workspace_retention_in_days = var.log_analytics_retention_in_days
  log_analytics_workspace_sku               = "PerGB2018"
  tags                                      = var.tags
}

# CCC.K8S.CN14.AR03 / CN11.AR02 / CN15.AR02: alert when cluster, access, policy,
# diagnostic or network-exposure configuration changes through Azure Resource Manager.
module "security_change_alert" {
  source    = "Azure/avm-res-insights-activitylogalert/azurerm"
  version   = "0.1.0"
  providers = { modtm = modtm }

  condition = {
    all_of = [
      {
        field  = "category"
        equals = "Administrative"
      },
      # Activity log alerts accept operationName only as equals leaves; containsAny is
      # rejected with ConditionFieldIsNull.
      {
        any_of = [for operation in [
          "Microsoft.ContainerService/managedClusters/write",
          "Microsoft.ContainerService/managedClusters/delete",
          "Microsoft.ContainerService/managedClusters/agentPools/write",
          "Microsoft.Authorization/roleAssignments/write",
          "Microsoft.Authorization/roleAssignments/delete",
          "Microsoft.Authorization/policyAssignments/write",
          "Microsoft.Authorization/policyAssignments/delete",
          "Microsoft.Insights/diagnosticSettings/write",
          "Microsoft.Insights/diagnosticSettings/delete",
          "Microsoft.Network/networkSecurityGroups/securityRules/write",
          "Microsoft.Network/networkSecurityGroups/securityRules/delete",
          ] : {
          field  = "operationName"
          equals = operation
        }]
      },
    ]
  }
  location         = var.location
  name             = "ala-ccc-security-changes-${random_string.name_suffix.result}"
  parent_id        = local.resource_group_id
  scopes           = [local.resource_group_id]
  description      = "CCC.K8S.CN14.AR03: changes to AKS, role or policy assignments, diagnostics or network security rules."
  enable_telemetry = var.enable_telemetry
  tags             = var.tags
}

# CCC.K8S.CN14.AR03: alert on in-cluster changes to RBAC bindings, admission webhooks and
# network policies made by non-system users. No published AVM module exists yet for
# scheduled query rules (avm-res-insights-scheduledqueryrule is Proposed), so AzAPI is used.
resource "azapi_resource" "kubernetes_security_change_alert" {
  location  = var.location
  name      = "sqr-ccc-k8s-security-changes-${random_string.name_suffix.result}"
  parent_id = local.resource_group_id
  type      = "Microsoft.Insights/scheduledQueryRules@2023-12-01"
  body = {
    kind = "LogAlert"
    properties = {
      displayName         = "CCC K8S security configuration change"
      description         = "CCC.K8S.CN14.AR03: Kubernetes RBAC, admission or network policy changed by a non-system identity."
      severity            = 2
      enabled             = true
      evaluationFrequency = "PT5M"
      windowSize          = "PT5M"
      scopes              = [module.log_analytics.resource_id]
      autoMitigate        = false
      skipQueryValidation = true
      criteria = {
        allOf = [{
          query           = local.kubernetes_security_change_query
          timeAggregation = "Count"
          operator        = "GreaterThan"
          threshold       = 0
          failingPeriods = {
            numberOfEvaluationPeriods = 1
            minFailingPeriodsToAlert  = 1
          }
        }]
      }
    }
  }
  response_export_values = []
  tags                   = var.tags
}
