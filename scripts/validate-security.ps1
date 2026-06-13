param(
    [string]$OrgAlias = "ServiceCloud"
)

Push-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "Validating security metadata against org: $OrgAlias"

sf project deploy start `
  --target-org $OrgAlias `
  --manifest manifest/package-security.xml `
  --dry-run `
  --verbose

$code = $LASTEXITCODE
Pop-Location
exit $code
