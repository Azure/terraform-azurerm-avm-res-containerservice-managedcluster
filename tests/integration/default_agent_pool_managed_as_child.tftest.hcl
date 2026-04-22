# Integration test proving the default_agent_pool_managed_as_child migration flow works
# end-to-end against real Azure infrastructure.
#
# Flow covered:
#   1. setup                                -- creates a resource group via the helper module.
#   2. create_with_flag_false               -- deploys a minimal AKS cluster with the default
#                                              agent pool embedded in the parent cluster PUT
#                                              (default_agent_pool_managed_as_child = false).
#   3. flip_flag_to_true_imports_pool       -- re-applies with the flag flipped to true. This
#                                              triggers the one-shot Terraform `import` block
#                                              that adopts the existing default agent pool
#                                              into the child module. No changes should be made
#                                              in Azure -- the adopted pool keeps its original
#                                              name and spec.
#   4. change_vm_size_replaces_pool         -- changes the default pool vm_size. The child
#                                              resource's create_before_destroy semantics create
#                                              a new pool with a suffixed name, AKS drains the
#                                              old pool, then Terraform deletes it. At the end
#                                              the child module reports a Succeeded provisioning
#                                              state on the new pool with the new vm_size.

# Common inputs shared across the three apply runs below. Each run overrides only what it needs
# to vary (the managed-as-child flag and the default_agent_pool vm_size).
variables {
  location  = "eastus"
  parent_id = ""
  default_agent_pool = {
    name     = "default"
    vm_size  = "Standard_DS2_v2"
    count_of = 1
  }
  managed_identities = {
    system_assigned = true
  }
  dns_prefix = "defaultitest"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

run "setup" {
  module {
    source = "./tests/integration/setup"
  }
}

run "create_with_flag_false" {
  command = apply

  variables {
    location                            = run.setup.resource_group_location
    name                                = run.setup.cluster_name
    parent_id                           = run.setup.resource_group_id
    default_agent_pool_managed_as_child = false
  }

  assert {
    condition     = azapi_resource.this.id != ""
    error_message = "Cluster resource must be created with a valid id."
  }

  assert {
    condition     = length(module.default_agent_pool) == 0
    error_message = "Child default_agent_pool module must not be instantiated when the flag is false."
  }

  # The parent body is the source of truth for what was PUT to Azure on initial create.
  assert {
    condition = anytrue([
      for pool in azapi_resource.this.body.properties.agentPoolProfiles :
      pool.name == "default" && lower(pool.vmSize) == lower("Standard_DS2_v2")
    ])
    error_message = "Parent cluster body must include a 'default' agent pool with vm_size Standard_DS2_v2."
  }
}

run "flip_flag_to_true_imports_pool" {
  command = apply

  variables {
    location                            = run.setup.resource_group_location
    name                                = run.setup.cluster_name
    parent_id                           = run.setup.resource_group_id
    default_agent_pool_managed_as_child = true
  }

  # The pool must be adopted into the child module at its original name.
  assert {
    condition     = length(module.default_agent_pool) == 1
    error_message = "Child default_agent_pool module must be instantiated when the flag is true."
  }

  assert {
    condition     = module.default_agent_pool[0].name == "default"
    error_message = "Adopted default agent pool must retain its original name after import (got: ${module.default_agent_pool[0].name})."
  }

  assert {
    condition     = module.default_agent_pool[0].provisioning_state == "Succeeded"
    error_message = "Adopted default agent pool must report Succeeded provisioning state."
  }

  # resource_id is populated only for non-data-only child modules.
  assert {
    condition     = module.default_agent_pool[0].resource_id != null && module.default_agent_pool[0].resource_id != ""
    error_message = "Adopted default agent pool must have a non-empty resource_id after import."
  }
}

run "change_vm_size_replaces_pool" {
  command = apply

  variables {
    location                            = run.setup.resource_group_location
    name                                = run.setup.cluster_name
    parent_id                           = run.setup.resource_group_id
    default_agent_pool_managed_as_child = true
    default_agent_pool = {
      name     = "default"
      vm_size  = "Standard_DS3_v2" # changed from Standard_DS2_v2
      count_of = 1
    }
  }

  # After CBD replacement the pool's name is suffixed with a 4-char hash.
  assert {
    condition     = startswith(module.default_agent_pool[0].name, "default") && length(module.default_agent_pool[0].name) == 11
    error_message = "Replaced default agent pool must have a hash-suffixed name of the form 'default<4hex>' (got: ${module.default_agent_pool[0].name})."
  }

  assert {
    condition     = module.default_agent_pool[0].name != "default"
    error_message = "Replaced default agent pool must not retain the original name 'default'."
  }

  assert {
    condition     = module.default_agent_pool[0].provisioning_state == "Succeeded"
    error_message = "Replaced default agent pool must report Succeeded provisioning state."
  }
}
