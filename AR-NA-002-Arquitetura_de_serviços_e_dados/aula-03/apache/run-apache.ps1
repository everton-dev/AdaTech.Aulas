param(
    [ValidateRange(1, 65535)]
    [int]$HostPort = 80
)

$ErrorActionPreference = "Stop"
$containerName = "meu-apache"
$siteDir = Join-Path $PSScriptRoot "site"

function Invoke-Docker {
    param([string[]]$DockerArguments)

    & docker @DockerArguments
    if ($LASTEXITCODE -ne 0) {
        throw "O comando 'docker $($DockerArguments -join ' ')' falhou com codigo $LASTEXITCODE."
    }
}

Write-Host "Baixando a imagem oficial httpd..."
Invoke-Docker @("pull", "httpd")

$existingContainer = docker ps --all --quiet --filter "name=^/${containerName}$"
if ($LASTEXITCODE -ne 0) {
    throw "Nao foi possivel consultar os containers existentes."
}

if ($existingContainer) {
    Write-Host "Removendo o container anterior $containerName..."
    Invoke-Docker @("rm", "--force", $containerName)
}

$portOwners = @(docker ps --filter "publish=$HostPort" --format "{{.Names}}")
if ($LASTEXITCODE -ne 0) {
    throw "Nao foi possivel verificar a porta $HostPort."
}

if ($portOwners.Count -gt 0) {
    throw "A porta $HostPort esta sendo usada por: $($portOwners -join ', '). Pare o container ou escolha outra porta com -HostPort."
}

Write-Host "Iniciando $containerName em http://localhost:$HostPort..."
Invoke-Docker @(
    "run",
    "--detach",
    "--name", $containerName,
    "--publish", "${HostPort}:80",
    "--volume", "${siteDir}:/usr/local/apache2/htdocs/:ro",
    "httpd"
)

Invoke-Docker @("ps", "--filter", "name=$containerName")
Write-Host "Abra http://localhost:$HostPort no navegador."