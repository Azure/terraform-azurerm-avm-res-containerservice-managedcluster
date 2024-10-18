## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
locals {
  test_regions = [
    "centralus",
    "southcentralus",
    "canadacentral",
    "eastus",
    "eastus2",
    "westus2",
    "westus3"
  ]
}
