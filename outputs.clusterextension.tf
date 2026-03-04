output "cluster_extension_resource_ids" {
  description = "A map of cluster extension keys to resource ids and names."
  value = { for cek, ce in module.clusterextension : cek => {
    resource_id = ce.resource_id
    name        = ce.name
    }
  }
}
