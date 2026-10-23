# Network foundation, created only when no existing subnets are supplied.
#
# One cluster VNet: AKS nodes, the delegated API-server subnet and private endpoints
# (container registry). No runner network is needed: keys are created through ARM.
#
# CCC.K8S.CN01.AR01 / CCC.Core.CN05: every subnet has an NSG whose default rules allow
# inbound traffic only from virtual networks and Azure Load Balancer.

module "resource_group" {
  source    = "Azure/avm-res-resources-resourcegroup/azurerm"
  version   = "0.4.0"
  providers = { modtm = modtm }
  count     = var.resource_group_id == null ? 1 : 0

  location         = var.location
  name             = "rg-ccc-${random_string.name_suffix.result}"
  enable_telemetry = var.enable_telemetry
  tags             = var.tags
}

module "network_security_groups" {
  source    = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version   = "0.6.0"
  providers = { modtm = modtm }
  for_each  = local.created_subnets

  location         = var.location
  name             = "nsg-ccc-${each.key}-${random_string.name_suffix.result}"
  parent_id        = local.resource_group_id
  enable_telemetry = var.enable_telemetry
  tags             = var.tags
}

module "virtual_networks" {
  source    = "Azure/avm-res-network-virtualnetwork/azurerm"
  version   = "0.22.3"
  providers = { modtm = modtm }
  for_each  = local.created_virtual_networks

  location         = var.location
  parent_id        = local.resource_group_id
  address_space    = [each.value.address_space]
  enable_telemetry = var.enable_telemetry
  name             = "vnet-ccc-${each.key}-${random_string.name_suffix.result}"
  subnets = {
    for key, subnet in each.value.subnets : key => {
      name           = "snet-ccc-${key}"
      address_prefix = subnet.address_prefix
      network_security_group = {
        id = module.network_security_groups["${each.key}-${key}"].resource_id
      }
      delegations = subnet.delegation == null ? null : [{
        name = "delegation"
        service_delegation = {
          name = subnet.delegation
        }
      }]
    }
  }
  tags = var.tags
}
