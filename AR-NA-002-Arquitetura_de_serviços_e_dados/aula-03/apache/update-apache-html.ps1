param(
    [string]$ContainerName = "meu-apache",
    [string]$HtmlPath = (Join-Path $PSScriptRoot "site\index.html")
)

$ErrorActionPreference = "Stop"
$apacheIndex = "/usr/local/apache2/htdocs/index.html"

function Invoke-Docker {
    param([string[]]$DockerArguments)

    & docker @DockerArguments
    if ($LASTEXITCODE -ne 0) {
        throw "O comando 'docker $($DockerArguments -join ' ')' falhou com codigo $LASTEXITCODE."
    }
}

if (-not (Test-Path -Path $HtmlPath -PathType Leaf)) {
    throw "O arquivo HTML '$HtmlPath' nao foi encontrado."
}

$runningContainer = docker ps --quiet --filter "name=^/${ContainerName}$"
if ($LASTEXITCODE -ne 0) {
    throw "Nao foi possivel consultar os containers em execucao."
}

if (-not $runningContainer) {
    throw "O container '$ContainerName' nao existe ou nao esta em execucao."
}

Write-Host "Criando backup da pagina atual..."
Invoke-Docker @(
    "exec", $ContainerName,
    "sh", "-c",
    "if [ -f '$apacheIndex' ]; then cp '$apacheIndex' '${apacheIndex}.backup'; fi"
)

Write-Host "Copiando '$HtmlPath' para o container $ContainerName..."
Invoke-Docker @("cp", $HtmlPath, "${ContainerName}:${apacheIndex}")

Write-Host "Pagina inicial atualizada com sucesso."
Invoke-Docker @("exec", $ContainerName, "ls", "-l", $apacheIndex)