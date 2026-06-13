param(
    [string]$OrgAlias = "ServiceCloud"
)

Push-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "Deploying ui metadata to org: $OrgAlias"

sf project deploy start `
  --target-org $OrgAlias `
  --manifest manifest/package-ui.xml `
  --verbose

$code = $LASTEXITCODE
Pop-Location
exit $code
