param(
    [string]$OrgAlias = "ServiceCloud"
)

# NOTE: --dry-run does not persist anything, so layers 2+ only validate cleanly
# against an org where the previous layers are already deployed.
# On a fresh org, run deploy-all.ps1 instead (it deploys layer by layer).
$steps = @(
    "validate-core.ps1",
    "validate-code.ps1",
    "validate-flexipages.ps1",
    "validate-ui.ps1",
    "validate-app.ps1",
    "validate-security.ps1",
    "validate-full.ps1"
)

foreach ($step in $steps) {
    & "$PSScriptRoot\$step" -OrgAlias $OrgAlias
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED at $step" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

Write-Host "All validation layers passed."
