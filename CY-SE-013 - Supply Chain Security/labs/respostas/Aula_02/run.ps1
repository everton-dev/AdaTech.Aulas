# Executa o Lab 02 de ponta a ponta. Requer: opa, conftest. jq e opcional (resumo de cobertura).
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Stop-WithError {
    param([string]$Message)
    Write-Host "ERRO: $Message"
    exit 1
}

# imagem na allowlist (approved_base) + usuario nao-root -> nenhuma regra deny casa
Set-Content -Path Dockerfile -NoNewline -Value "FROM cgr.dev/chainguard/static:latest`nCOPY app /app`nUSER 1001`nCMD [`"/app`"]`n"
# imagem ubuntu nao esta na allowlist e USER e root -> duas violacoes independentes
Set-Content -Path Dockerfile.inseguro -NoNewline -Value "FROM ubuntu:latest`nCOPY app /app`nUSER root`nCMD [`"/app`"]`n"

Write-Host "== 1) Dockerfile seguro -> deve PASSAR"
conftest test Dockerfile --policy policies/docker/
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 2) Dockerfile inseguro (ubuntu + root) -> deve FALHAR com 2 violacoes"
# "ubuntu" nao e imagem aprovada (regra de base) e USER root (regra de usuario)
conftest test Dockerfile.inseguro --parser dockerfile --policy policies/docker/
if ($LASTEXITCODE -eq 0) {
    Stop-WithError "deveria falhar"
}

Write-Host ""
Write-Host "== 3) Deployment seguro -> deve PASSAR"
# runAsUser != 0, limite de memoria definido e sem segredo em texto plano no env
conftest test manifests/deployment.yaml --policy policies/kubernetes/
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 4) Deployment inseguro (UID 0, sem memoria, token literal) -> deve FALHAR"
# cada problema casa com uma regra deny diferente: runAsUser == 0, limits.memory
# ausente, e variavel com nome sensivel sem vir de secretKeyRef
conftest test manifests/deployment-insegura.yaml --policy policies/kubernetes/
if ($LASTEXITCODE -eq 0) {
    Stop-WithError "deveria falhar"
}

Write-Host ""
Write-Host "== 5) Testes unitarios + cobertura"
# cobertura mostra se todas as regras deny das policies tem pelo menos um teste exercitando-as
opa test policies/ -v
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (Get-Command jq -ErrorAction SilentlyContinue) {
    opa test policies/ --coverage --format=json | jq '.coverage'
} else {
    Write-Host "   jq ausente, pulando resumo de cobertura"
}

Write-Host ""
Write-Host "Lab 02 OK"
