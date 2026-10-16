# Deploy Storage Account ARM Template
# This script deploys a storage account using the ARM template

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$DeploymentName = "storage-account-deployment",
    
    [Parameter(Mandatory=$false)]
    [string]$TemplateFile = "storage-account.template.json",
    
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "storage-account.parameters.json"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "Starting Storage Account deployment..." -ForegroundColor Green

try {
    # Check if Azure CLI is installed and user is logged in
    az version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI is not installed or not accessible. Please install Azure CLI first."
    }

    # Check if user is logged in
    $account = az account show 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Not logged in to Azure. Please login first..." -ForegroundColor Yellow
        az login
    } else {
        Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Cyan
        Write-Host "Subscription: $($account.name) ($($account.id))" -ForegroundColor Cyan
    }

    # Check if resource group exists, create if it doesn't
    Write-Host "Checking if resource group '$ResourceGroupName' exists..." -ForegroundColor Yellow
    az group show --name $ResourceGroupName 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Resource group '$ResourceGroupName' does not exist. Creating..." -ForegroundColor Yellow
        az group create --name $ResourceGroupName --location $Location
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create resource group '$ResourceGroupName'"
        }
        Write-Host "Resource group '$ResourceGroupName' created successfully." -ForegroundColor Green
    } else {
        Write-Host "Resource group '$ResourceGroupName' already exists." -ForegroundColor Green
    }

    # Validate template files exist
    if (!(Test-Path $TemplateFile)) {
        throw "Template file '$TemplateFile' not found in current directory."
    }
    if (!(Test-Path $ParametersFile)) {
        throw "Parameters file '$ParametersFile' not found in current directory."
    }

    # Validate deployment first
    Write-Host "Validating ARM template deployment..." -ForegroundColor Yellow
    az deployment group validate `
        --resource-group $ResourceGroupName `
        --template-file $TemplateFile `
        --parameters @$ParametersFile

    if ($LASTEXITCODE -ne 0) {
        throw "Template validation failed. Please check your template and parameters."
    }
    Write-Host "Template validation successful." -ForegroundColor Green

    # Preview what will be deployed
    Write-Host "Previewing deployment changes..." -ForegroundColor Yellow
    az deployment group what-if `
        --resource-group $ResourceGroupName `
        --template-file $TemplateFile `
        --parameters @$ParametersFile

    # Ask for confirmation
    $confirmation = Read-Host "Do you want to proceed with the deployment? (y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "Deployment cancelled by user." -ForegroundColor Yellow
        exit 0
    }

    # Deploy the template
    Write-Host "Deploying storage account..." -ForegroundColor Green
    $deployment = az deployment group create `
        --resource-group $ResourceGroupName `
        --name $DeploymentName `
        --template-file $TemplateFile `
        --parameters @$ParametersFile `
        --output json | ConvertFrom-Json

    if ($LASTEXITCODE -ne 0) {
        throw "Deployment failed."
    }

    Write-Host "Deployment completed successfully!" -ForegroundColor Green
    Write-Host "Deployment Name: $DeploymentName" -ForegroundColor Cyan
    Write-Host "Storage Account Name: $($deployment.properties.outputs.storageAccountName.value)" -ForegroundColor Cyan
    Write-Host "Primary Blob Endpoint: $($deployment.properties.outputs.primaryBlobEndpoint.value)" -ForegroundColor Cyan

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Script completed successfully!" -ForegroundColor Green
