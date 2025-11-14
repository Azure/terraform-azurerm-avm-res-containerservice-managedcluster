# https://learn.microsoft.com/azure/templates/microsoft.insights/datacollectionendpoints?pivots=deployment-language-terraform
resource "azapi_resource" "dce_msprom" {
  location  = var.location
  name      = "MSProm-${var.location}-${basename(var.aks_cluster_id)}"
  parent_id = var.parent_id
  type      = "Microsoft.Insights/dataCollectionEndpoints@2023-03-11"
  body = {
    kind       = "Linux"
    properties = {}
  }
  tags = var.tags
}

# https://learn.microsoft.com/azure/templates/microsoft.insights/datacollectionrules?pivots=deployment-language-terraform
resource "azapi_resource" "dcr_msprom" {
  location  = var.location
  name      = "MSProm-${var.location}-${basename(var.aks_cluster_id)}"
  parent_id = var.parent_id
  type      = "Microsoft.Insights/dataCollectionRules@2023-03-11"
  body = {
    kind = "Linux"
    properties = {
      dataCollectionEndpointId = azapi_resource.dce_msprom.id
      dataSources = {
        prometheusForwarder = [
          {
            name = "PrometheusDataSource"
            streams = [
              "Microsoft-PrometheusMetrics"
            ]
          }
        ]
      }
      destinations = {
        monitoringAccounts = [
          {
            accountResourceId = var.prometheus_workspace_id
            name              = "MonitoringAccount1"
          }
        ]
      }
      dataFlows = [
        {
          destinations = [
            "MonitoringAccount1"
          ]
          streams = [
            "Microsoft-PrometheusMetrics"
          ]
        }
      ]
    }
  }
  tags = var.tags
}

# https://learn.microsoft.com/azure/templates/microsoft.insights/datacollectionruleassociations?pivots=deployment-language-terraform
resource "azapi_resource" "dcr_msprom_aks" {
  name      = "dcr-${basename(var.aks_cluster_id)}"
  parent_id = var.aks_cluster_id
  type      = "Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11"
  body = {
    properties = {
      dataCollectionRuleId = azapi_resource.dcr_msprom.id
    }
  }
}
resource "azapi_resource" "dce_msprom_aks" {
  name      = "configurationAccessEndpoint"
  parent_id = var.aks_cluster_id
  type      = "Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11"
  body = {
    properties = {
      dataCollectionEndpointId = azapi_resource.dce_msprom.id
    }
  }
}

# https://learn.microsoft.com/azure/templates/microsoft.alertsmanagement/prometheusrulegroups?pivots=deployment-language-terraform
resource "azapi_resource" "prg_node" {
  location  = var.location
  name      = "NodeRecordingRulesRuleGroup - ${basename(var.aks_cluster_id)}"
  parent_id = var.parent_id
  type      = "Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01"
  body = {
    properties = {
      clusterName = basename(var.aks_cluster_id)
      enabled     = true
      interval    = "PT1M"
      rules = [
        {
          record     = "instance:node_num_cpu:sum"
          expression = "count without (cpu, mode) (node_cpu_seconds_total{job=\"node\",mode=\"idle\"})"
        },
        {
          record     = "instance:node_cpu_utilisation:rate5m"
          expression = "1 - avg without (cpu) (sum without (mode) (rate(node_cpu_seconds_total{job=\"node\", mode=~\"idle|iowait|steal\"}[5m])))"
        },
        {
          record     = "instance:node_load1_per_cpu:ratio"
          expression = "(node_load1{job=\"node\"}/  instance:node_num_cpu:sum{job=\"node\"})"
        },
        {
          record     = "instance:node_memory_utilisation:ratio"
          expression = "1 - ((node_memory_MemAvailable_bytes{job=\"node\"} or (node_memory_Buffers_bytes{job=\"node\"} + node_memory_Cached_bytes{job=\"node\"} + node_memory_MemFree_bytes{job=\"node\"} + node_memory_Slab_bytes{job=\"node\"})) / node_memory_MemTotal_bytes{job=\"node\"})"
        },
        {
          record     = "instance:node_vmstat_pgmajfault:rate5m"
          expression = "rate(node_vmstat_pgmajfault{job=\"node\"}[5m])"
        },
        {
          record     = "instance_device:node_disk_io_time_seconds:rate5m"
          expression = "rate(node_disk_io_time_seconds_total{job=\"node\", device!=\"\"}[5m])"
        },
        {
          record     = "instance_device:node_disk_io_time_weighted_seconds:rate5m"
          expression = "rate(node_disk_io_time_weighted_seconds_total{job=\"node\", device!=\"\"}[5m])"
        },
        {
          record     = "instance:node_network_receive_bytes_excluding_lo:rate5m"
          expression = "sum without (device) (rate(node_network_receive_bytes_total{job=\"node\", device!=\"lo\"}[5m]))"
        },
        {
          record     = "instance:node_network_transmit_bytes_excluding_lo:rate5m"
          expression = "sum without (device) (rate(node_network_transmit_bytes_total{job=\"node\", device!=\"lo\"}[5m]))"
        },
        {
          record     = "instance:node_network_receive_drop_excluding_lo:rate5m"
          expression = "sum without (device) (rate(node_network_receive_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
        },
        {
          record     = "instance:node_network_transmit_drop_excluding_lo:rate5m"
          expression = "sum without (device) (rate(node_network_transmit_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
        }
      ]
      scopes = [
        var.prometheus_workspace_id
      ]
    }
  }
  tags = var.tags
}

# https://learn.microsoft.com/azure/azure-monitor/containers/prometheus-metrics-scrape-default
resource "azapi_resource" "prg_ux" {
  location  = var.location
  name      = "UXRecordingRulesRuleGroup - ${basename(var.aks_cluster_id)}"
  parent_id = var.parent_id
  type      = "Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01"
  body = {
    properties = {
      clusterName = basename(var.aks_cluster_id)
      enabled     = true
      interval    = "PT1M"
      description = "UX Recording Rules for Linux"
      rules = [
        {
          record     = "ux:pod_cpu_usage:sum_irate"
          expression = "(sum by (namespace, pod, cluster, microsoft_resourceid) (\n\tirate(container_cpu_usage_seconds_total{container != \"\", pod != \"\", job = \"cadvisor\"}[5m])\n)) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n(max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{pod != \"\", job = \"kube-state-metrics\"}))"
        },
        {
          record     = "ux:controller_cpu_usage:sum_irate"
          expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (\nux:pod_cpu_usage:sum_irate\n)\n"
        },
        {
          record     = "ux:pod_workingset_memory:sum"
          expression = "(\n\t    sum by (namespace, pod, cluster, microsoft_resourceid) (\n\t\tcontainer_memory_working_set_bytes{container != \"\", pod != \"\", job = \"cadvisor\"}\n\t    )\n\t) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n(max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{pod != \"\", job = \"kube-state-metrics\"}))"
        },
        {
          record     = "ux:controller_workingset_memory:sum"
          expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (\nux:pod_workingset_memory:sum\n)"
        },
        {
          record     = "ux:pod_rss_memory:sum"
          expression = "(\n\t    sum by (namespace, pod, cluster, microsoft_resourceid) (\n\t\tcontainer_memory_rss{container != \"\", pod != \"\", job = \"cadvisor\"}\n\t    )\n\t) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n(max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{pod != \"\", job = \"kube-state-metrics\"}))"
        },
        {
          record     = "ux:controller_rss_memory:sum"
          expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (\nux:pod_rss_memory:sum\n)"
        },
        {
          record     = "ux:pod_container_count:sum"
          expression = "sum by (node, created_by_name, created_by_kind, namespace, cluster, pod, microsoft_resourceid) (\n(\n(\nsum by (container, pod, namespace, cluster, microsoft_resourceid) (kube_pod_container_info{container != \"\", pod != \"\", container_id != \"\", job = \"kube-state-metrics\"})\nor sum by (container, pod, namespace, cluster, microsoft_resourceid) (kube_pod_init_container_info{container != \"\", pod != \"\", container_id != \"\", job = \"kube-state-metrics\"})\n)\n* on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n(\nmax by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (\n\tkube_pod_info{pod != \"\", job = \"kube-state-metrics\"}\n)\n)\n)\n\n)"
        },
        {
          record     = "ux:controller_container_count:sum"
          expression = "sum by (node, created_by_name, created_by_kind, namespace, cluster, microsoft_resourceid) (\nux:pod_container_count:sum\n)"
        },
        {
          record     = "ux:pod_container_restarts:max"
          expression = "max by (node, created_by_name, created_by_kind, namespace, cluster, pod, microsoft_resourceid) (\n(\n(\nmax by (container, pod, namespace, cluster, microsoft_resourceid) (kube_pod_container_status_restarts_total{container != \"\", pod != \"\", job = \"kube-state-metrics\"})\nor sum by (container, pod, namespace, cluster, microsoft_resourceid) (kube_pod_init_status_restarts_total{container != \"\", pod != \"\", job = \"kube-state-metrics\"})\n)\n* on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n(\nmax by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (\n\tkube_pod_info{pod != \"\", job = \"kube-state-metrics\"}\n)\n)\n)\n\n)"
        },
        {
          record     = "ux:controller_container_restarts:max"
          expression = "max by (node, created_by_name, created_by_kind, namespace, cluster, microsoft_resourceid) (\nux:pod_container_restarts:max\n)"
        },
        {
          record     = "ux:pod_resource_limit:sum"
          expression = "(sum by (cluster, pod, namespace, resource, microsoft_resourceid) (\n(\n\tmax by (cluster, microsoft_resourceid, pod, container, namespace, resource)\n\t (kube_pod_container_resource_limits{container != \"\", pod != \"\", job = \"kube-state-metrics\"})\n)\n)unless (count by (pod, namespace, cluster, resource, microsoft_resourceid)\n\t(kube_pod_container_resource_limits{container != \"\", pod != \"\", job = \"kube-state-metrics\"})\n!= on (pod, namespace, cluster, microsoft_resourceid) group_left()\n sum by (pod, namespace, cluster, microsoft_resourceid)\n (kube_pod_container_info{container != \"\", pod != \"\", job = \"kube-state-metrics\"}) \n)\n\n)* on (namespace, pod, cluster, microsoft_resourceid) group_left (node, created_by_kind, created_by_name)\n(\n\tkube_pod_info{pod != \"\", job = \"kube-state-metrics\"}\n)"
        },
        {
          record     = "ux:controller_resource_limit:sum"
          expression = "sum by (cluster, namespace, created_by_name, created_by_kind, node, resource, microsoft_resourceid) (\nux:pod_resource_limit:sum\n)"
        },
        {
          record     = "ux:controller_pod_phase_count:sum"
          expression = "sum by (cluster, phase, node, created_by_kind, created_by_name, namespace, microsoft_resourceid) ( (\n(kube_pod_status_phase{job=\"kube-state-metrics\",pod!=\"\"})\n or (label_replace((count(kube_pod_deletion_timestamp{job=\"kube-state-metrics\",pod!=\"\"}) by (namespace, pod, cluster, microsoft_resourceid) * count(kube_pod_status_reason{reason=\"NodeLost\", job=\"kube-state-metrics\"} == 0) by (namespace, pod, cluster, microsoft_resourceid)), \"phase\", \"terminating\", \"\", \"\"))) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n(\nmax by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (\nkube_pod_info{job=\"kube-state-metrics\",pod!=\"\"}\n)\n)\n)"
        },
        {
          record     = "ux:cluster_pod_phase_count:sum"
          expression = "sum by (cluster, phase, node, namespace, microsoft_resourceid) (\nux:controller_pod_phase_count:sum\n)"
        },
        {
          record     = "ux:node_cpu_usage:sum_irate"
          expression = "sum by (instance, cluster, microsoft_resourceid) (\n(1 - irate(node_cpu_seconds_total{job=\"node\", mode=\"idle\"}[5m]))\n)"
        },
        {
          record     = "ux:node_memory_usage:sum"
          expression = "sum by (instance, cluster, microsoft_resourceid) ((\nnode_memory_MemTotal_bytes{job = \"node\"}\n- node_memory_MemFree_bytes{job = \"node\"} \n- node_memory_cached_bytes{job = \"node\"}\n- node_memory_buffers_bytes{job = \"node\"}\n))"
        },
        {
          record     = "ux:node_network_receive_drop_total:sum_irate"
          expression = "sum by (instance, cluster, microsoft_resourceid) (irate(node_network_receive_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
        },
        {
          record     = "ux:node_network_transmit_drop_total:sum_irate"
          expression = "sum by (instance, cluster, microsoft_resourceid) (irate(node_network_transmit_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
        },
      ]
      scopes = [
        var.prometheus_workspace_id,
        var.aks_cluster_id
      ]
    }
  }
  tags = var.tags
}

resource "azapi_resource" "prg_k8s" {
  location  = var.location
  name      = "KubernetesRecordingRulesRuleGroup - ${basename(var.aks_cluster_id)}"
  parent_id = var.parent_id
  type      = "Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01"
  body = {
    properties = {
      clusterName = basename(var.aks_cluster_id)
      enabled     = true
      interval    = "PT1M"
      rules = [
        {
          record     = "node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate"
          expression = "sum by (cluster, namespace, pod, container) (irate(container_cpu_usage_seconds_total{job=\"cadvisor\", image!=\"\"}[5m])) * on (cluster, namespace, pod) group_left(node) topk by (cluster, namespace, pod) (1, max by(cluster, namespace, pod, node) (kube_pod_info{node!=\"\"}))"
        },
        {
          record     = "node_namespace_pod_container:container_memory_working_set_bytes"
          expression = "container_memory_working_set_bytes{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1, max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
        },
        {
          record     = "node_namespace_pod_container:container_memory_rss"
          expression = "container_memory_rss{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1, max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
        },
        {
          record     = "node_namespace_pod_container:container_memory_cache"
          expression = "container_memory_cache{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1, max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
        },
        {
          record     = "node_namespace_pod_container:container_memory_swap"
          expression = "container_memory_swap{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1, max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
        },
        {
          record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_requests"
          expression = "kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"} * on(namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ((kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
        },
        {
          record     = "namespace_memory:kube_pod_container_resource_requests:sum"
          expression = "sum by (namespace, cluster) (sum by (namespace, pod, cluster) (max by (namespace, pod, container, cluster) (kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"}) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)))"
        },
        {
          record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests"
          expression = "kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"} * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ((kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
        },
        {
          record     = "namespace_cpu:kube_pod_container_resource_requests:sum"
          expression = "sum by (namespace, cluster) (sum by(namespace, pod, cluster) (max by(namespace, pod, container, cluster) (kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"}) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)))"
        },
        {
          record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_limits"
          expression = "kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"} * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ((kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
        },
        {
          record     = "namespace_memory:kube_pod_container_resource_limits:sum"
          expression = "sum by (namespace, cluster) (sum by (namespace, pod, cluster) (max by (namespace, pod, container, cluster) (kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"}) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)))"
        },
        {
          record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits"
          expression = "kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"} * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ( (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1) )"
        },
        {
          record     = "namespace_cpu:kube_pod_container_resource_limits:sum"
          expression = "sum by (namespace, cluster) (sum by (namespace, pod, cluster) (max by(namespace, pod, container, cluster) (kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"}) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)))"
        },
        {
          record     = "namespace_workload_pod:kube_pod_owner:relabel"
          expression = "max by (cluster, namespace, workload, pod) (label_replace(label_replace(kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"ReplicaSet\"}, \"replicaset\", \"$1\", \"owner_name\", \"(.*)\") * on(replicaset, namespace) group_left(owner_name) topk by(replicaset, namespace) (1, max by (replicaset, namespace, owner_name) (kube_replicaset_owner{job=\"kube-state-metrics\"})), \"workload\", \"$1\", \"owner_name\", \"(.*)\"))"
          labels = {
            "workload_type" = "deployment"
          }
        },
        {
          record     = "namespace_workload_pod:kube_pod_owner:relabel"
          expression = "max by (cluster, namespace, workload, pod) (label_replace(kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"DaemonSet\"}, \"workload\", \"$1\", \"owner_name\", \"(.*)\"))"
          labels = {
            "workload_type" = "daemonset"
          }
        },
        {
          record     = "namespace_workload_pod:kube_pod_owner:relabel"
          expression = "max by (cluster, namespace, workload, pod) (label_replace(kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"StatefulSet\"}, \"workload\", \"$1\", \"owner_name\", \"(.*)\"))"
          labels = {
            "workload_type" = "statefulset"
          }
        },
        {
          record     = "namespace_workload_pod:kube_pod_owner:relabel"
          expression = "max by (cluster, namespace, workload, pod) (label_replace(kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"Job\"}, \"workload\", \"$1\", \"owner_name\", \"(.*)\"))"
          labels = {
            "workload_type" = "job"
          }
        },
        {
          record     = ":node_memory_MemAvailable_bytes:sum"
          expression = "sum(node_memory_MemAvailable_bytes{job=\"node\"} or (node_memory_Buffers_bytes{job=\"node\"} + node_memory_Cached_bytes{job=\"node\"} + node_memory_MemFree_bytes{job=\"node\"} + node_memory_Slab_bytes{job=\"node\"})) by (cluster)"
        },
        {
          record     = "cluster:node_cpu:ratio_rate5m"
          expression = "sum(rate(node_cpu_seconds_total{job=\"node\",mode!=\"idle\",mode!=\"iowait\",mode!=\"steal\"}[5m])) by (cluster) /count(sum(node_cpu_seconds_total{job=\"node\"}) by (cluster, instance, cpu)) by (cluster)"
        }
      ]
      scopes = [
        var.prometheus_workspace_id,
      ]
    }
  }
  tags = var.tags
}

# https://learn.microsoft.com/azure/templates/microsoft.insights/datacollectionrules?pivots=deployment-language-terraform
resource "azapi_resource" "dcr_msci" {
  location  = var.location
  name      = "MSCI-${var.location}-${basename(var.aks_cluster_id)}"
  parent_id = var.parent_id
  type      = "Microsoft.Insights/dataCollectionRules@2023-03-11"
  body = {
    kind = "Linux"
    properties = {
      dataSources = {
        extensions = [
          {
            name          = "ContainerInsightsExtension"
            extensionName = "ContainerInsights"
            extensionSettings = {
              dataCollectionSettings : {
                interval : "1m",
                namespaceFilteringMode : "Off",
                enableContainerLogV2 : true
              }
            }
            streams = [
              "Microsoft-ContainerLog",
              "Microsoft-ContainerLogV2",
              "Microsoft-KubeEvents",
              "Microsoft-KubePodInventory"
            ]
          }
        ]

      }
      destinations = {
        logAnalytics = [
          {
            name                = "ciworkspace"
            workspaceResourceId = var.log_analytics_workspace_id
          }
        ]
      }
      dataFlows = [
        {
          destinations = [
            "ciworkspace"
          ]
          streams = [
            "Microsoft-ContainerLog",
            "Microsoft-ContainerLogV2",
            "Microsoft-KubeEvents",
            "Microsoft-KubePodInventory"
          ]
        }
      ]
    }
  }
  tags = var.tags
}

# https://learn.microsoft.com/azure/templates/microsoft.insights/datacollectionruleassociations?pivots=deployment-language-terraform
resource "azapi_resource" "dcr_msci_aks" {
  name      = "msci-${basename(var.aks_cluster_id)}"
  parent_id = var.aks_cluster_id
  type      = "Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11"
  body = {
    properties = {
      dataCollectionRuleId = azapi_resource.dcr_msci.id
    }
  }
}
