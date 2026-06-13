param(
    [string]$OrgAlias = "ServiceCloud"
)

$steps = @(
    "deploy-core.ps1",
    "deploy-code.ps1",
    "deploy-flexipages.ps1",
    "deploy-ui.ps1",
    "deploy-app.ps1",
    "deploy-security.ps1",
    "validate-full.ps1"
)

foreach ($step in $steps) {
    & "$PSScriptRoot\$step" -OrgAlias $OrgAlias
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAILED at $step" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

Write-Host "All layers deployed and final validation passed."
