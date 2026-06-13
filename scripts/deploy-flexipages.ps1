param(
    [string]$OrgAlias = "ServiceCloud"
)

Push-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "Deploying flexipages metadata to org: $OrgAlias"

sf project deploy start `
  --target-org $OrgAlias `
  --manifest manifest/package-flexipages.xml `
  --verbose

$code = $LASTEXITCODE
Pop-Location
exit $code
