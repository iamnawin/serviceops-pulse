param(
    [string]$OrgAlias = "ServiceCloud"
)

Push-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "Deploying app metadata to org: $OrgAlias"

sf project deploy start `
  --target-org $OrgAlias `
  --manifest manifest/package-app.xml `
  --verbose

$code = $LASTEXITCODE
Pop-Location
exit $code
