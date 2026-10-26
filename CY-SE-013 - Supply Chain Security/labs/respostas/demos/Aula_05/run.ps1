# Demo Aula 05 - mesmo pipeline do Lab 05 (Dependency-Track), mas sobre a Function App
# .NET 10 propria (app/) em vez do node:14-alpine publico. Sobe a stack, gera o SBOM da
# imagem com Syft, envia pro Dependency-Track e mostra os achados (inclui a dependencia
# plantada Newtonsoft.Json 12.0.1 / CVE-2024-21907). Requer: docker compose, syft, jq
# (sanitizacao de licencas), curl (para os 2 POSTs sem corpo onde o Invoke-RestMethod do
# Windows PowerShell 5.1 insiste em mandar um Content-Type que o DT rejeita, e para o
# upload multipart do SBOM, ja que -Form so existe a partir do PowerShell 6.1), pwsh.
# Uso: .\run.ps1 | .\run.ps1 -Cleanup
# Atencao: usa as mesmas portas 8081/8080 do labs/respostas/Aula_05 - nao rode os dois
# stacks ao mesmo tempo (.\run.ps1 -Cleanup aqui, ou no outro, antes de trocar).
param(
    [switch]$Cleanup
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$DtUrl = if ($env:DT_URL) { $env:DT_URL } else { 'http://localhost:8081' }
$env:DT_URL = $DtUrl
$AdminPass = if ($env:ADMIN_PASS) { $env:ADMIN_PASS } else { 'LabSupplyChain#2026' }
$ProjectName = 'ada-supply-demo'
$ProjectVersion = 'demo'

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
foreach ($permission in 'VIEW_PORTFOLIO', 'VIEW_POLICY_VIOLATION', 'VIEW_VULNERABILITY', 'POLICY_MANAGEMENT', 'PORTFOLIO_MANAGEMENT') {
    # Invoke-RestMethod (Windows PowerShell 5.1) sempre manda um Content-Type default
    # num POST sem corpo, mesmo com -ContentType $null; o endpoint nao aceita nenhum
    # body e responde 415 nesse caso. curl.exe (sem -d) nao manda esse header, igual ao bash original.
    curl.exe -s -X POST -H "Authorization: Bearer $token" "$DtUrl/api/v1/permission/$permission/team/$teamUuid" | Out-Null
}
Write-Host "   DT_KEY=$($dtKey.Substring(0, 8))... (guarde em variavel de ambiente, nunca no Git)"

Write-Host ""
Write-Host "== 3b) Habilitar fonte OSV para NuGet (NVD completo demora demais; OSV cobre o ecossistema NuGet, usado pela Function App)"
Invoke-RestMethod -Method Post -Headers $authHeaders -ContentType 'application/json' -Uri "$DtUrl/api/v1/configProperty" -Body (
    @{ groupName = 'vuln-source'; propertyName = 'google.osv.enabled'; propertyValue = 'NuGet' } | ConvertTo-Json
) | Out-Null
docker compose restart apiserver | Out-Null
Wait-Until -MaxAttempts 60 -DelaySeconds 5 -ProgressMessage "aguardando API" -Condition {
    try { Invoke-RestMethod -Uri "$DtUrl/api/version" -ErrorAction Stop | Out-Null; $true } catch { $false }
} | Out-Null
Wait-Until -MaxAttempts 60 -DelaySeconds 10 -ProgressMessage "aguardando espelho OSV (NuGet ~2-3 min)" -Condition {
    # Continue temporario: com ErrorActionPreference=Stop, redirecionar o stderr de um
    # comando nativo que falhar (2>$null) trava o script em vez de so descartar a saida.
    $ErrorActionPreference = 'Continue'
    $logs = docker compose logs --since 10m apiserver 2>$null
    $ErrorActionPreference = 'Stop'
    $logs -match 'mirror completed for NuGet|Google OSV mirroring complete'
} | Out-Null
$token = Invoke-RestMethod -Method Post -Uri "$DtUrl/api/v1/user/login" -Body @{ username = 'admin'; password = $AdminPass }
$authHeaders = @{ Authorization = "Bearer $token" }

Write-Host ""
Write-Host "== 4) Build da imagem da Function App (traz Newtonsoft.Json 12.0.1 plantada de proposito)"
docker build -t "${ProjectName}:local" ./app
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 5) Gerar SBOM da imagem (CycloneDX 1.5: DT 4.12 ainda nao le 1.6/1.7)"
syft "${ProjectName}:local" -o "cyclonedx-json@1.5=$ProjectName.cdx.json" -q
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
(Get-Content "$ProjectName.cdx.json" -Raw | ConvertFrom-Json).components.Count

Write-Host ""
Write-Host "== 5b) Sanitizar licencas (o schema CycloneDX 1.5 do DT rejeita 'licenses' com mais de 1 item e 'license.id' fora da lista SPDX dele; o Syft as vezes gera ambos para pacotes NuGet)"
$licenseFilter = @'
def fixentry: if type=="object" and has("license") and (.license|type=="object") and (.license|has("id")) then
    .license |= ({name: .id} + (if has("url") then {url} else {} end))
  else . end;
walk(
  if type=="object" and has("licenses") and (.licenses|type=="array") then
    .licenses |= (if length>1 then [.[0]] else . end) | .licenses |= map(fixentry)
  else . end
)
'@
$licenseFilterPath = Join-Path $PSScriptRoot 'sanitize-licenses.jq'
Set-Content -Path $licenseFilterPath -Value $licenseFilter -NoNewline
jq -f $licenseFilterPath "$ProjectName.cdx.json" | Set-Content -Path "$ProjectName.fixed.cdx.json"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Remove-Item $licenseFilterPath

Write-Host ""
Write-Host "== 6) Enviar SBOM"
$apiKeyHeaders = @{ 'X-Api-Key' = $dtKey }
# -Form so existe a partir do PowerShell 6.1; no Windows PowerShell 5.1 (que nao tem esse
# parametro) usamos curl.exe para o multipart/form-data, igual ao script bash original.
$uploadJson = curl.exe -s -X POST "$DtUrl/api/v1/bom" -H "X-Api-Key: $dtKey" `
    -F "autoCreate=true" -F "projectName=$ProjectName" -F "projectVersion=$ProjectVersion" `
    -F "bom=@$ProjectName.fixed.cdx.json"
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
Write-Host "== 7) Forcar reanalise de vulnerabilidades (policy OSV so comecou a mirror depois do upload acima nao, mas a reanalise garante achados atualizados)"
$projectUuid = (Invoke-RestMethod -Headers $apiKeyHeaders -Uri "$DtUrl/api/v1/project/lookup?name=$ProjectName&version=$ProjectVersion").uuid
# mesmo problema do passo 3: POST sem corpo via Invoke-RestMethod leva a 415; usa curl.exe aqui tambem
$analyzeToken = (curl.exe -s -X POST -H "Authorization: Bearer $token" "$DtUrl/api/v1/finding/project/$projectUuid/analyze" | ConvertFrom-Json).token
Wait-Until -MaxAttempts 60 -DelaySeconds 5 -ProgressMessage "aguardando reanalise" -Condition {
    (Invoke-RestMethod -Headers $apiKeyHeaders -Uri "$DtUrl/api/v1/event/token/$analyzeToken").processing -eq $false
} | Out-Null
Invoke-RestMethod -Headers $apiKeyHeaders -Uri "$DtUrl/api/v1/metrics/project/$projectUuid/refresh" | Out-Null
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "== 8) Resultados - vulnerabilidades encontradas no projeto ${ProjectName}:${ProjectVersion}"
$findings = Invoke-RestMethod -Headers $apiKeyHeaders -Uri "$DtUrl/api/v1/finding/project/$projectUuid"
$findings | ForEach-Object {
    [PSCustomObject]@{
        COMPONENTE      = $_.component.name
        VERSAO          = $_.component.version
        VULNERABILIDADE = $_.vulnerability.vulnId
        SEVERIDADE      = $_.vulnerability.severity
    }
} | Format-Table -AutoSize

Write-Host ""
Write-Host "Demo Aula 05 OK - UI: http://localhost:8080 (admin / $AdminPass), projeto '$ProjectName'."
Write-Host "Limpe com .\run.ps1 -Cleanup"
