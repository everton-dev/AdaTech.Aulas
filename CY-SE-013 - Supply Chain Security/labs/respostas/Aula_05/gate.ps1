# Gate de pipeline: falha (exit 1) se o projeto tiver violacoes de policy com estado FAIL.
# Variaveis de ambiente obrigatorias: DT_URL, DT_KEY. Opcionais: PROJECT_NAME, PROJECT_VERSION.
$ErrorActionPreference = 'Stop'

# Equivalente a ": ${VAR:?mensagem}" do bash: para a execucao se a variavel nao existir
function Get-RequiredEnvVar {
    param([string]$Name, [string]$ErrorMessage)
    $value = [System.Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrEmpty($value)) {
        Write-Error $ErrorMessage
        exit 1
    }
    return $value
}

$DtUrl = Get-RequiredEnvVar -Name 'DT_URL' -ErrorMessage 'defina DT_URL (ex.: http://localhost:8081)'
$DtKey = Get-RequiredEnvVar -Name 'DT_KEY' -ErrorMessage 'defina DT_KEY (API key do time Automation)'
$ProjectName = if ($env:PROJECT_NAME) { $env:PROJECT_NAME } else { 'lab-node14' }
$ProjectVersion = if ($env:PROJECT_VERSION) { $env:PROJECT_VERSION } else { 'baseline' }

$headers = @{ 'X-Api-Key' = $DtKey }

$project = Invoke-RestMethod -Headers $headers -Uri "$DtUrl/api/v1/project/lookup?name=$ProjectName&version=$ProjectVersion"
$projectUuid = $project.uuid

$violations = Invoke-RestMethod -Headers $headers -Uri "$DtUrl/api/v1/violation/project/$projectUuid"
$failCount = @($violations | Where-Object { $_.policyCondition.policy.violationState -eq 'FAIL' }).Count

$metrics = Invoke-RestMethod -Headers $headers -Uri "$DtUrl/api/v1/metrics/project/$projectUuid/current"
$critical = if ($null -ne $metrics.critical) { $metrics.critical } else { 0 }

Write-Host "Projeto: $ProjectName@$ProjectVersion ($projectUuid)"
Write-Host "CVEs criticas: $critical | Violacoes FAIL: $failCount"

if ($failCount -gt 0) {
    Write-Host "Pipeline bloqueado: $failCount violacao(oes) de policy."
    exit 1
}
Write-Host "Gate aprovado."
