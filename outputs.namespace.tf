output "namespace_resource_ids" {
  description = "A map of namespace keys to resource ids."
  value = { for nsk, ns in module.namespace : nsk => {
    resource_id = ns.resource_id
    name        = ns.name
    }
  }
}
