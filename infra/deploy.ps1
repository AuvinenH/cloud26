# Deploy the Azure environment only after showing and reviewing the what-if result.

# ----- Variables: edit the student name and paths if necessary ----------
$YourName = "henri"
$ResourceGroup = "rg-cloud26-$YourName-dev"
$TemplateFile = "infra/main.bicep"
$ParametersFile = "infra/dev.bicepparam"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$TemplatePath = Join-Path $ProjectRoot $TemplateFile
$ParametersPath = Join-Path $ProjectRoot $ParametersFile

# ----- Check that Azure CLI authentication works ------------------------
$accountJson = az account show 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($accountJson)) {
    Write-Host "Azure login check failed. Run 'az login' and try again." -ForegroundColor Red
    exit 1
}

$account = $accountJson | ConvertFrom-Json
Write-Host "Signed in as: $($account.user.name)" -ForegroundColor Green
Write-Host "Target resource group: $ResourceGroup"

# ----- Store the password only in the current process environment --------
if ([string]::IsNullOrEmpty($env:POSTGRES_ADMIN_PASSWORD)) {
    $env:POSTGRES_ADMIN_PASSWORD = Read-Host "PostgreSQL admin password"
}

# ----- Preview the deployment without making changes ---------------------
Write-Host ""
Write-Host "=== What-if (no changes are made yet) ===" -ForegroundColor Cyan
az deployment group what-if `
    --resource-group $ResourceGroup `
    --template-file $TemplatePath `
    --parameters $ParametersPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "What-if failed. No deployment was started." -ForegroundColor Red
    exit 1
}

# ----- Require explicit confirmation before deployment -------------------
$answer = Read-Host "Deploy? (y/n)"
if ($answer -ne "y") {
    Write-Host "Deployment cancelled. No changes were made." -ForegroundColor Yellow
    exit 0
}

# ----- Apply the reviewed deployment -------------------------------------
Write-Host "Deploying..." -ForegroundColor Cyan
$deploymentJson = az deployment group create `
    --resource-group $ResourceGroup `
    --template-file $TemplatePath `
    --parameters $ParametersPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed." -ForegroundColor Red
    exit 1
}

# ----- Print only the non-secret deployment outputs ----------------------
$deployment = $deploymentJson | ConvertFrom-Json
$outputs = $deployment.properties.outputs

Write-Host ""
Write-Host "Deployment completed." -ForegroundColor Green
Write-Host "Web app URL: $($outputs.webAppUrl.value)"
Write-Host "Server FQDN: $($outputs.postgresServerFqdn.value)"
