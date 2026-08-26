variable "aks_cluster_id" {
  type        = string
  description = "The resource ID of the AKS cluster"
  nullable    = false
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be created"
  nullable    = false
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The resource ID of the Log Analytics workspace"
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = "The resource ID of the parent resource group"
  nullable    = false
}

variable "prometheus_workspace_id" {
  type        = string
  description = "The resource ID of the Azure Monitor workspace for managed Prometheus"
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    alertsmanagement_prometheus_rule_groups    = optional(list(string), [])
    insights_data_collection_endpoints         = optional(list(string), [])
    insights_data_collection_rule_associations = optional(list(string), [])
    insights_data_collection_rules             = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths to ignore for each AzAPI resource, in dot notation. Changes take
effect only after apply, and ignored configuration is not sent to Azure until the
path is removed.

- `alertsmanagement_prometheus_rule_groups` - Paths ignored on the Prometheus rule groups.
- `insights_data_collection_endpoints` - Paths ignored on the data collection endpoint.
- `insights_data_collection_rule_associations` - Paths ignored on the data collection rule associations.
- `insights_data_collection_rules` - Paths ignored on the data collection rules.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    alertsmanagement_prometheus_rule_groups    = optional(string, "Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01")
    insights_data_collection_endpoints         = optional(string, "Microsoft.Insights/dataCollectionEndpoints@2023-03-11")
    insights_data_collection_rule_associations = optional(string, "Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11")
    insights_data_collection_rules             = optional(string, "Microsoft.Insights/dataCollectionRules@2023-03-11")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by this module.

- `alertsmanagement_prometheus_rule_groups` - Resource type and API version for the Prometheus rule groups.
- `insights_data_collection_endpoints` - Resource type and API version for the data collection endpoint.
- `insights_data_collection_rule_associations` - Resource type and API version for the data collection rule associations.
- `insights_data_collection_rules` - Resource type and API version for the data collection rules.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to the AzAPI resources in this module.

- `error_message_regex` - Regular expressions matching error messages that should be retried.
- `interval_seconds` - Initial delay between retries, in seconds.
- `max_interval_seconds` - Maximum delay between retries, in seconds.
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Timeouts applied to the AzAPI resources in this module.

- `create` - Timeout for create operations.
- `read` - Timeout for read operations.
- `update` - Timeout for update operations.
- `delete` - Timeout for delete operations.
DESCRIPTION
}
