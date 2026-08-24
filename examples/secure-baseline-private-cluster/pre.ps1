$ErrorActionPreference = "Stop"

$features = @(
  "ManagedGatewayAPIPreview",
  "ApplicationLoadBalancerPreview"
)

foreach ($feature in $features) {
  & az feature register --namespace Microsoft.ContainerService --name $feature --only-show-errors --output none
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to register Microsoft.ContainerService/$feature."
  }
}

& az provider register --namespace Microsoft.ContainerService --only-show-errors --output none
if ($LASTEXITCODE -ne 0) {
  throw "Failed to register the Microsoft.ContainerService resource provider."
}

$deadline = (Get-Date).AddMinutes(30)
do {
  $states = foreach ($feature in $features) {
    (& az feature show --namespace Microsoft.ContainerService --name $feature --query properties.state --output tsv).Trim()
  }

  if ($states | Where-Object { $_ -ne "Registered" }) {
    Start-Sleep -Seconds 15
  }
} while (($states | Where-Object { $_ -ne "Registered" }) -and (Get-Date) -lt $deadline)

if ($states | Where-Object { $_ -ne "Registered" }) {
  throw "Timed out waiting for AKS preview feature registration. Current states: $($states -join ', ')."
}