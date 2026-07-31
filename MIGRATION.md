# AzureRM interface migration

The migration of locks, role assignments, diagnostic settings, and private endpoints to AzAPI is staged so existing Azure resources can be retained.

## Prepare on 0.7.x

The preparation release keeps the AzureRM resources but uses `Azure/avm-utl-interfaces/azure` to retain each role assignment's UUID and adapts the existing `diagnostic_settings` input to the AVM v2 diagnostic schema.

After updating the module source and running `terraform init -upgrade`, adopt every existing role assignment UUID into the utility module before applying. Replace `<module>` and `<key>` with the module call and map key:

```shell
terraform state show 'module.<module>.azurerm_role_assignment.this["<key>"]'
terraform import 'module.<module>.module.interfaces.random_uuid.role_assignment_name["<key>"]' '<existing-role-assignment-name>'
terraform plan
```

The final plan must not replace the role assignment. Repeat the import for every entry in `role_assignments`. The utility generates and retains the UUID for new role assignments.

## Upgrade to 0.8.0

The lock, role assignment, and diagnostic setting states move automatically. Private endpoints require explicit state adoption because one legacy `azurerm_private_endpoint` state object can contain both the endpoint and its private DNS zone group, while AzAPI manages those as two resources.

Update the module source to 0.8.0 and run `terraform init -upgrade`, but do not plan or apply yet. For each private endpoint, first record its Azure resource ID, then remove only the legacy Terraform state entries. These commands do not delete Azure resources:

```shell
terraform state rm 'module.<module>.azurerm_private_endpoint_application_security_group_association.this["<pe-key>-<asg-key>"]'
terraform state rm 'module.<module>.azurerm_private_endpoint.this_managed_dns_zone_groups["<pe-key>"]'
terraform import 'module.<module>.azapi_resource.private_endpoints["<pe-key>"]' '<private-endpoint-resource-id>'
terraform import 'module.<module>.azapi_resource.private_dns_zone_groups["<pe-key>"]' '<private-endpoint-resource-id>/privateDnsZoneGroups/<dns-zone-group-name>'
```

Omit the ASG command when the endpoint has no ASG associations. For an endpoint created with `private_endpoints_manage_dns_zone_group = false`, use the corresponding `this_unmanaged_dns_zone_groups` address and omit the private DNS zone group import. Also omit that import when the endpoint has no `private_dns_zone_resource_ids`.

Run `terraform plan` after all imports. Do not apply if Terraform proposes deleting or replacing the managed cluster, lock, role assignment, diagnostic setting, private endpoint, DNS zone group, or ASG association.
