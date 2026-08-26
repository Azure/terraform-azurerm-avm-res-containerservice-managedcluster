# https://learn.microsoft.com/azure/templates/microsoft.insights/actiongroups?pivots=deployment-language-terraform
resource "azapi_resource" "ag" {
  location  = "Global"
  name      = "RecommendedAlertRules-AG-1"
  parent_id = var.parent_id
  type      = var.resource_types.insights_action_groups
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
  ignore_body_changes    = length(var.ignore_body_changes.insights_action_groups) > 0 ? var.ignore_body_changes.insights_action_groups : null
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

# https://learn.microsoft.com/azure/templates/microsoft.insights/metricalerts?pivots=deployment-language-terraform
resource "azapi_resource" "metricalert_cpu" {
  location  = "Global"
  name      = "CPU Usage Percentage - ${basename(var.aks_cluster_id)}"
  parent_id = var.parent_id
  type      = var.resource_types.insights_metric_alerts
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
  ignore_body_changes    = length(var.ignore_body_changes.insights_metric_alerts) > 0 ? var.ignore_body_changes.insights_metric_alerts : null
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource" "metricalert_memory" {
  location  = "Global"
  name      = "Memory Working Set Percentage - ${basename(var.aks_cluster_id)}"
  parent_id = var.parent_id
  type      = var.resource_types.insights_metric_alerts
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
  ignore_body_changes    = length(var.ignore_body_changes.insights_metric_alerts) > 0 ? var.ignore_body_changes.insights_metric_alerts : null
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
