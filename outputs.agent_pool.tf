output "agentpool_resource_ids" {
  description = "A map of nodepool keys to resource ids."
  value = { for apk, ap in module.nodepools : apk => {
    resource_id = ap.resource_id
    name        = ap.name
    }
  }
}
