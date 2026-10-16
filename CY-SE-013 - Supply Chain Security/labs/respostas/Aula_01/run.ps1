# Executa o Lab 01 de ponta a ponta. Requer: opa, conftest.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# Encapsula "echo ERRO: ...; exit 1" para nao repetir o mesmo bloco varias vezes (DRY)
function Stop-WithError {
    param([string]$Message)
    Write-Host "ERRO: $Message"
    exit 1
}

# a policy so tem uma regra que casa com este input (User == "root"),
# entao o resultado esperado e exatamente 1 violacao, nunca mais que isso
Write-Host "== 1) Input inseguro (root) -> deve retornar 1 violacao"
opa eval --format pretty --data policies/docker/security.rego --input inputs/image_root.json "data.docker.security.deny"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$countRoot = opa eval --format raw --data policies/docker/security.rego --input inputs/image_root.json "count(data.docker.security.deny)"
if ($countRoot -ne '1') {
    Stop-WithError "esperado 1 violacao para input root, obtido $countRoot"
}

Write-Host ""
Write-Host "== 2) Input corrigido (UID 1001) -> deve retornar conjunto vazio"
# User != "root" e != null, logo nenhuma das duas regras deny dispara
opa eval --format pretty --data policies/docker/security.rego --input inputs/image_ok.json "data.docker.security.deny"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$countOk = opa eval --format raw --data policies/docker/security.rego --input inputs/image_ok.json "count(data.docker.security.deny)"
if ($countOk -ne '0') {
    Stop-WithError "esperado 0 violacoes para input corrigido, obtido $countOk"
}

Write-Host ""
Write-Host "== 3) Dockerfile inseguro via Conftest -> deve FALHAR (exit != 0)"
# aqui o Conftest parseia o Dockerfile de verdade (nao um JSON de exemplo);
# se "conftest test" tiver sucesso (exit 0) e porque a policy NAO pegou o problema
conftest test Dockerfile --policy policies/dockerfile.rego
if ($LASTEXITCODE -eq 0) {
    Stop-WithError "Dockerfile inseguro deveria falhar"
}

Write-Host ""
Write-Host "== 4) Dockerfile corrigido via Conftest -> deve PASSAR"
# USER nao-root definido -> nenhuma regra deny casa, Conftest retorna sucesso
conftest test Dockerfile.ok --parser dockerfile --policy policies/dockerfile.rego
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 5) Testes unitarios da politica"
# valida a logica Rego isoladamente (sem depender de Dockerfile/Conftest)
opa test policies/ -v
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Lab 01 OK"
