param(
    [string]$OrgAlias = "ServiceCloud"
)

Push-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "Deploying code metadata to org: $OrgAlias"

sf project deploy start `
  --target-org $OrgAlias `
  --manifest manifest/package-code.xml `
  --verbose

$code = $LASTEXITCODE
Pop-Location
exit $code
