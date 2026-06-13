param(
    [string]$OrgAlias = "ServiceCloud"
)

Push-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "Validating full metadata against org: $OrgAlias"

sf project deploy start `
  --target-org $OrgAlias `
  --manifest manifest/package-full.xml `
  --dry-run `
  --verbose

$code = $LASTEXITCODE
Pop-Location
exit $code
