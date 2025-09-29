# https://learn.microsoft.com/azure/templates/microsoft.insights/actiongroups?pivots=deployment-language-terraform
resource "azapi_resource" "ag" {
  location  = "Global"
  name      = "RecommendedAlertRules-AG-1"
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.Insights/actionGroups@2024-10-01-preview"
  body = {
    properties = {
      groupShortName = "recalert1"
      enabled        = true
      emailReceivers = [
        {
          name                 = "Email_-EmailAction-"
          emailAddress         = var.alert_email
          useCommonAlertSchema = true
        }
      ]
    }
  }
}

# https://learn.microsoft.com/azure/templates/microsoft.insights/metricalerts?pivots=deployment-language-terraform
resource "azapi_resource" "metricalert_cpu" {
  location  = "Global"
  name      = "CPU Usage Percentage - ${var.aks_cluster_name}"
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.Insights/metricAlerts@2018-03-01"
  body = {
    properties = {
      severity            = 3
      enabled             = true
      scopes              = [var.aks_cluster_id]
      evaluationFrequency = "PT5M"
      windowSize          = "PT5M"
      criteria = {
        allOf = [
          {
            threshold       = 95
            name            = "Metric1"
            metricNamespace = "Microsoft.ContainerService/managedClusters"
            metricName      = "node_cpu_usage_percentage"
            operator        = "GreaterThan"
            timeAggregation = "Average"
            criterionType   = "StaticThresholdCriterion"
          }
        ]
        "odata.type" = "Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria"
      }
      targetResourceType = "Microsoft.ContainerService/managedClusters"
      actions = [
        {
          actionGroupId     = azapi_resource.ag.id
          webHookProperties = {}
        }
      ]
    }
  }
}

resource "azapi_resource" "metricalert_memory" {
  location  = "Global"
  name      = "Memory Working Set Percentage - ${var.aks_cluster_name}"
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  type      = "Microsoft.Insights/metricAlerts@2018-03-01"
  body = {
    properties = {
      severity            = 3
      enabled             = true
      scopes              = [var.aks_cluster_id]
      evaluationFrequency = "PT5M"
      windowSize          = "PT5M"
      criteria = {
        allOf = [
          {
            threshold       = 100
            name            = "Metric1"
            metricNamespace = "Microsoft.ContainerService/managedClusters"
            metricName      = "node_memory_working_set_percentage"
            operator        = "GreaterThan"
            timeAggregation = "Average"
            criterionType   = "StaticThresholdCriterion"
          }
        ]
        "odata.type" = "Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria"
      }
      targetResourceType = "Microsoft.ContainerService/managedClusters"
      actions = [
        {
          actionGroupId     = azapi_resource.ag.id
          webHookProperties = {}
        }
      ]
    }
  }
}
