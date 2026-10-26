# Lab 05 - Dependency-Track de ponta a ponta (sobe stack, cria API key via API, ingere SBOM,
# cria policy CRITICAL -> FAIL, roda o gate). Requer: docker compose, syft, pwsh (para chamar
# gate.ps1), curl (para os POSTs sem corpo e o upload multipart do SBOM: no Windows PowerShell
# 5.1, Invoke-RestMethod manda um Content-Type que o DT rejeita com 415 nesses POSTs, e -Form
# so existe a partir do PowerShell 6.1).
# Uso: .\run.ps1 | .\run.ps1 -Cleanup
param(
    [switch]$Cleanup
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$DtUrl = if ($env:DT_URL) { $env:DT_URL } else { 'http://localhost:8081' }
$env:DT_URL = $DtUrl
$AdminPass = if ($env:ADMIN_PASS) { $env:ADMIN_PASS } else { 'LabSupplyChain#2026' }

# Repete uma condicao ate ela ser verdadeira ou estourar o numero de tentativas,
# imprimindo um "." a cada tentativa (equivalente ao "for + curl + sleep" repetido no script original)
function Wait-Until {
    param([scriptblock]$Condition, [int]$MaxAttempts, [int]$DelaySeconds, [string]$ProgressMessage)
    Write-Host -NoNewline "   $ProgressMessage"
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        if (& $Condition) { Write-Host ""; return $true }
        Write-Host -NoNewline "."
        Start-Sleep -Seconds $DelaySeconds
    }
    Write-Host ""
    return $false
}

if ($Cleanup) {
    docker compose down -v
    exit 0
}

Write-Host "== 1) Subir Dependency-Track"
docker compose up -d
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Wait-Until -MaxAttempts 120 -DelaySeconds 5 -ProgressMessage "aguardando API (1a vez: 3-5 min; baixa NVD em background)" -Condition {
    try { Invoke-RestMethod -Uri "$DtUrl/api/version" -ErrorAction Stop | Out-Null; $true } catch { $false }
} | Out-Null
try {
    (Invoke-RestMethod -Uri "$DtUrl/api/version") | Select-Object application, version | ConvertTo-Json -Compress
} catch {
    Write-Host "API nao subiu. Veja: docker logs aula_05-apiserver-1  (precisa de 4 GB de heap)"
    exit 1
}

Write-Host ""
Write-Host "== 2) Trocar senha padrao (admin/admin) e obter token"
# Primeiro login forca troca de senha; o endpoint forceChangePassword faz isso sem UI.
try {
    Invoke-RestMethod -Method Post -Uri "$DtUrl/api/v1/user/forceChangePassword" -Body @{
        username = 'admin'; password = 'admin'; newPassword = $AdminPass; confirmPassword = $AdminPass
    } | Out-Null
} catch { }
$token = Invoke-RestMethod -Method Post -Uri "$DtUrl/api/v1/user/login" -Body @{ username = 'admin'; password = $AdminPass }
if ($token.Length -le 20) {
    Write-Host "ERRO: falha no login"
    exit 1
}
$authHeaders = @{ Authorization = "Bearer $token" }

Write-Host ""
Write-Host "== 3) Gerar API key do time Automation"
$teams = Invoke-RestMethod -Headers $authHeaders -Uri "$DtUrl/api/v1/team"
$teamUuid = ($teams | Where-Object { $_.name -eq 'Automation' }).uuid
$dtKey = (Invoke-RestMethod -Method Put -Headers $authHeaders -Uri "$DtUrl/api/v1/team/$teamUuid/key").key
$env:DT_KEY = $dtKey
# Automation precisa de permissoes de leitura para o gate consultar violacoes/metricas
foreach ($permission in 'VIEW_PORTFOLIO', 'VIEW_POLICY_VIOLATION', 'VIEW_VULNERABILITY', 'POLICY_MANAGEMENT', 'PORTFOLIO_MANAGEMENT') {
    # Invoke-RestMethod (Windows PowerShell 5.1) sempre manda um Content-Type default
    # num POST sem corpo, mesmo sem -ContentType; o endpoint nao aceita nenhum body e
    # responde 415 nesse caso. curl.exe (sem -d) nao manda esse header.
    curl.exe -s -X POST -H "Authorization: Bearer $token" "$DtUrl/api/v1/permission/$permission/team/$teamUuid" | Out-Null
}
Write-Host "   DT_KEY=$($dtKey.Substring(0, 8))... (guarde em variavel de ambiente, nunca no Git)"

Write-Host ""
Write-Host "== 3b) Habilitar fonte OSV (NVD feeds costumam falhar/demorar; OSV cobre Alpine e npm, o que o node:14-alpine usa)"
# Em DT 4.12 o espelho OSV so roda no boot ou a cada 24h -> habilita e reinicia o apiserver.
# Restringimos a Alpine+npm para o espelho levar ~2 min (Debian/Maven levam muito mais).
Invoke-RestMethod -Method Post -Headers $authHeaders -ContentType 'application/json' -Uri "$DtUrl/api/v1/configProperty" -Body (
    @{ groupName = 'vuln-source'; propertyName = 'google.osv.enabled'; propertyValue = 'Alpine;npm' } | ConvertTo-Json
) | Out-Null
docker compose restart apiserver | Out-Null
Wait-Until -MaxAttempts 60 -DelaySeconds 5 -ProgressMessage "aguardando API" -Condition {
    try { Invoke-RestMethod -Uri "$DtUrl/api/version" -ErrorAction Stop | Out-Null; $true } catch { $false }
} | Out-Null
Wait-Until -MaxAttempts 60 -DelaySeconds 10 -ProgressMessage "aguardando espelho OSV (Alpine, npm ~2-3 min)" -Condition {
    # Continue temporario: com ErrorActionPreference=Stop, redirecionar o stderr de um
    # comando nativo que falhar (2>$null) trava o script em vez de so descartar a saida.
    $ErrorActionPreference = 'Continue'
    $logs = docker compose logs --since 10m apiserver 2>$null
    $ErrorActionPreference = 'Stop'
    $logs -match 'mirror completed for (npm|Alpine)|Google OSV mirroring complete'
} | Out-Null
$token = Invoke-RestMethod -Method Post -Uri "$DtUrl/api/v1/user/login" -Body @{ username = 'admin'; password = $AdminPass }
$authHeaders = @{ Authorization = "Bearer $token" }

Write-Host ""
Write-Host "== 4) Gerar SBOM de imagem com CVEs conhecidas (CycloneDX 1.5: DT 4.12 ainda nao le 1.6/1.7)"
syft node:14-alpine -o cyclonedx-json@1.5=node14.cdx.json -q
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
(Get-Content node14.cdx.json | ConvertFrom-Json).components.Count

Write-Host ""
Write-Host "== 5) Enviar SBOM"
$apiKeyHeaders = @{ 'X-Api-Key' = $dtKey }
# -Form so existe a partir do PowerShell 6.1; no Windows PowerShell 5.1 (que nao tem esse
# parametro) usamos curl.exe para o multipart/form-data.
$uploadJson = curl.exe -s -X POST "$DtUrl/api/v1/bom" -H "X-Api-Key: $dtKey" `
    -F "autoCreate=true" -F "projectName=lab-node14" -F "projectVersion=baseline" `
    -F "bom=@node14.cdx.json"
$upload = $uploadJson | ConvertFrom-Json
$upload | ConvertTo-Json -Compress
if (-not $upload.token) {
    Write-Host "ERRO: upload rejeitado"
    exit 1
}
$bomToken = $upload.token
Wait-Until -MaxAttempts 60 -DelaySeconds 5 -ProgressMessage "aguardando processamento do SBOM" -Condition {
    (Invoke-RestMethod -Headers $apiKeyHeaders -Uri "$DtUrl/api/v1/event/token/$bomToken").processing -eq $false
} | Out-Null

Write-Host ""
Write-Host "== 6) Policy: Severity is CRITICAL -> FAIL (aplicada ao projeto)"
$project = Invoke-RestMethod -Headers $apiKeyHeaders -Uri "$DtUrl/api/v1/project/lookup?name=lab-node14&version=baseline"
$projectUuid = $project.uuid
$policy = Invoke-RestMethod -Method Put -Headers $authHeaders -ContentType 'application/json' -Uri "$DtUrl/api/v1/policy" -Body (
    @{ name = 'Bloqueio de CVE critica'; operator = 'ANY'; violationState = 'FAIL' } | ConvertTo-Json
)
$policyUuid = $policy.uuid
Invoke-RestMethod -Method Put -Headers $authHeaders -ContentType 'application/json' -Uri "$DtUrl/api/v1/policy/$policyUuid/condition" -Body (
    @{ subject = 'SEVERITY'; operator = 'IS'; value = 'CRITICAL' } | ConvertTo-Json
) | Out-Null
Invoke-RestMethod -Method Post -Headers $authHeaders -Uri "$DtUrl/api/v1/policy/$policyUuid/project/$projectUuid" | Out-Null
# associar a policy ao projeto NAO reavalia nada sozinho (so persiste a associacao).
# o PolicyEngine so roda dentro do upload do SBOM ou de uma analise explicita --
# como a policy foi criada DEPOIS do upload (passo 5), precisamos forcar a reavaliacao agora.
# mesmo problema do passo 3: POST sem corpo via Invoke-RestMethod leva a 415; usa curl.exe aqui tambem
$analyzeToken = (curl.exe -s -X POST -H "Authorization: Bearer $token" "$DtUrl/api/v1/finding/project/$projectUuid/analyze" | ConvertFrom-Json).token
Wait-Until -MaxAttempts 60 -DelaySeconds 5 -ProgressMessage "aguardando avaliacao da policy" -Condition {
    # poll no token do evento em vez de 'sleep' fixo: so seguimos quando o DT confirma
    # que terminou de processar, nao quando "achamos" que ja deu tempo
    (Invoke-RestMethod -Headers $apiKeyHeaders -Uri "$DtUrl/api/v1/event/token/$analyzeToken").processing -eq $false
} | Out-Null
# forca recalculo de metricas do projeto para o gate ler numeros atualizados
Invoke-RestMethod -Headers $apiKeyHeaders -Uri "$DtUrl/api/v1/metrics/project/$projectUuid/refresh" | Out-Null
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "== 7) Gate"
# gate.ps1 roda como processo filho (pwsh) para que seu "exit 1" nao encerre este script,
# da mesma forma que "./gate.sh" roda em subshell no bash original
$env:PROJECT_NAME = 'lab-node14'
$env:PROJECT_VERSION = 'baseline'
pwsh -NoProfile -File (Join-Path $PSScriptRoot 'gate.ps1')
$gateExitCode = $LASTEXITCODE
Write-Host "exit code do gate: $gateExitCode  (1 = bloqueado, esperado para node:14-alpine)"

Write-Host ""
Write-Host "== 8) Auditoria Python local"
# complementa o gate do Dependency-Track: aqui auditamos as dependencias Python
# usadas pelo proprio laboratorio (fora do fluxo de SBOM/DT visto nos passos anteriores)
# Continue temporario: com ErrorActionPreference=Stop, redirecionar o stderr de um
# comando nativo que falhar (2>$null) trava o script em vez de so descartar a saida.
$ErrorActionPreference = 'Continue'
python -m venv .venv 2>$null
$ErrorActionPreference = 'Stop'
$pythonExe = if (Test-Path .venv\Scripts\python.exe) { '.venv\Scripts\python.exe' } else { '.venv/bin/python' }
& $pythonExe -m pip install -q -r python/requirements.txt pip-audit
& $pythonExe -m pip_audit -r python/requirements.txt --strict

Write-Host ""
Write-Host "Lab 05 OK - UI: http://localhost:8080 (admin / $AdminPass). Limpe com .\run.ps1 -Cleanup"
