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

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "resource_types" {
  type = object({
    insights_data_collection_endpoints         = optional(string, "Microsoft.Insights/dataCollectionEndpoints@2023-03-11")
    insights_data_collection_rules             = optional(string, "Microsoft.Insights/dataCollectionRules@2023-03-11")
    insights_data_collection_rule_associations = optional(string, "Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11")
    alertsmanagement_prometheus_rule_groups    = optional(string, "Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01")
  })
  default     = {}
  description = "AzAPI resource type overrides for monitoring resources."
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Retry configuration applied to every supported AzAPI resource declared by this module."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Default per-operation timeouts applied to every supported AzAPI resource declared by this module."
}

variable "ignore_body_changes" {
  type = object({
    insights_data_collection_endpoints         = optional(list(string), [])
    insights_data_collection_rules             = optional(list(string), [])
    insights_data_collection_rule_associations = optional(list(string), [])
    alertsmanagement_prometheus_rule_groups    = optional(list(string), [])
  })
  default     = {}
  description = "Body-relative dot-notation paths to ignore for each AzAPI resource. Changes take effect only after an apply."
  nullable    = false
}
