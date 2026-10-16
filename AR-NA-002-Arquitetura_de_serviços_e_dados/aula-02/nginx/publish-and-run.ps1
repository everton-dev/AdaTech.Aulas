param(
    [string]$DockerHubUser = $env:DOCKERHUB_USER,
    [ValidateRange(1, 65535)]
    [int]$HostPort = 80
)

$ErrorActionPreference = "Stop"
$containerName = "curriculo-wiki-nginx"
$siblingContainerName = "curriculo-wiki-apache"

if ([string]::IsNullOrWhiteSpace($DockerHubUser)) {
    throw "Uso: ./publish-and-run.ps1 <usuario-dockerhub> [porta-host]. Outra opcao e definir DOCKERHUB_USER."
}

function Invoke-Docker {
    param([string[]]$DockerArguments)

    & docker @DockerArguments
    if ($LASTEXITCODE -ne 0) {
        throw "O comando 'docker $($DockerArguments -join ' ')' falhou com codigo $LASTEXITCODE."
    }
}

$projectDir = Split-Path -Parent $PSScriptRoot
$dockerfile = Join-Path $PSScriptRoot "Dockerfile"
$versionFile = Join-Path $PSScriptRoot "version.txt"
$repository = "${DockerHubUser}/curriculo-wiki-nginx"
$versionContent = if (Test-Path $versionFile) { Get-Content $versionFile -Raw } else { $null }
$currentVersion = 0
if (-not [string]::IsNullOrWhiteSpace($versionContent) -and
    -not [int]::TryParse($versionContent.Trim(), [ref]$currentVersion)) {
    throw "O arquivo '$versionFile' deve conter apenas um numero inteiro."
}
$nextVersion = $currentVersion + 1
$versionedImage = "${repository}:v${nextVersion}"
$latestImage = "${repository}:latest"

Write-Host "Construindo versao v$nextVersion..."
Invoke-Docker @("build", "--file", $dockerfile, "--tag", $versionedImage, "--tag", $latestImage, $projectDir)

Write-Host "Publicando $versionedImage no Docker Hub..."
Invoke-Docker @("push", $versionedImage)
Set-Content -Path $versionFile -Value $nextVersion

Write-Host "Atualizando $latestImage no Docker Hub..."
Invoke-Docker @("push", $latestImage)

Write-Host "Baixando a imagem publicada..."
Invoke-Docker @("pull", $versionedImage)

$existingContainer = docker ps --all --quiet --filter "name=^/${containerName}$"
if ($LASTEXITCODE -ne 0) {
    throw "Nao foi possivel consultar os containers existentes."
}

if ($existingContainer) {
    Invoke-Docker @("rm", "--force", $containerName)
}

$portOwners = @(docker ps --filter "publish=$HostPort" --format "{{.Names}}")
if ($LASTEXITCODE -ne 0) {
    throw "Nao foi possivel verificar se a porta $HostPort esta disponivel."
}

foreach ($portOwner in $portOwners) {
    if ($portOwner -eq $siblingContainerName) {
        Write-Host "Parando $siblingContainerName para liberar a porta $HostPort..."
        Invoke-Docker @("stop", $siblingContainerName)
    }
    else {
        throw "A porta $HostPort ja esta sendo usada pelo container '$portOwner'. Pare-o ou informe outra porta em -HostPort."
    }
}

Write-Host "Iniciando $containerName em http://localhost:$HostPort..."
Invoke-Docker @(
    "run",
    "--detach",
    "--name", $containerName,
    "--publish", "${HostPort}:80",
    "--restart", "unless-stopped",
    $versionedImage
)

Invoke-Docker @("ps", "--filter", "name=$containerName")