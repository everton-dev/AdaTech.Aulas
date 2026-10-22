# Lab 03 - Gatekeeper em cluster kind. Requer: docker, kind, kubectl.
# Uso: .\run.ps1          (cria cluster, instala, testa)
#      .\run.ps1 -Cleanup (apaga o cluster)
param(
    [switch]$Cleanup
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$Cluster = 'policy-lab'
$GkVersion = 'v3.18.2'

function Stop-WithError {
    param([string]$Message)
    Write-Host "ERRO: $Message"
    exit 1
}

# Repete uma condicao ate ela ser verdadeira ou estourar o numero de tentativas;
# evita duplicar o padrao "for + sleep + break" usado varias vezes no script original (DRY)
function Wait-Until {
    param(
        [scriptblock]$Condition,
        [int]$MaxAttempts,
        [int]$DelaySeconds
    )
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        if (& $Condition) { return $true }
        Start-Sleep -Seconds $DelaySeconds
    }
    return $false
}

if ($Cleanup) {
    kind delete cluster --name $Cluster
    exit 0
}

Write-Host "== 1) Cluster kind"
$clusters = kind get clusters
if ($clusters -notcontains $Cluster) {
    kind create cluster --name $Cluster
}
kubectl cluster-info --context "kind-$Cluster" | Out-Null

Write-Host ""
Write-Host "== 2) Instalar Gatekeeper $GkVersion"
# Gatekeeper roda como admission webhook: ele intercepta requests ao API server
# e so libera (ou nao) a criacao do recurso depois de avaliar as policies.
kubectl apply -f "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/$GkVersion/deploy/gatekeeper.yaml"
kubectl -n gatekeeper-system rollout status deploy/gatekeeper-controller-manager --timeout=180s
kubectl -n gatekeeper-system rollout status deploy/gatekeeper-audit --timeout=180s

Write-Host ""
Write-Host "== 3) ConstraintTemplate"
# O ConstraintTemplate define a regra em Rego (nao roda nada sozinho); ele gera
# um novo CRD (K8sPSPRunAsNonRoot) que sera usado para instanciar a Constraint.
kubectl apply -f templates/runasnonroot.yaml
# aguarda o CRD gerado pelo template ficar disponivel
Wait-Until -MaxAttempts 30 -DelaySeconds 2 -Condition {
    kubectl get crd k8spsprunasnonroot.constraints.gatekeeper.sh *> $null
    $LASTEXITCODE -eq 0
} | Out-Null

Write-Host ""
Write-Host "== 4a) Constraint em DRYRUN -> Pod inseguro e ADMITIDO, mas aparece em status.violations"
# dryrun simula o efeito da policy sem bloquear nada: util para medir o impacto
# antes de ligar o enforcement e quebrar workloads existentes em producao.
kubectl apply -f constraints/run-as-nonroot-dryrun.yaml
Start-Sleep -Seconds 5
kubectl apply -f manifests/bad-pod.yaml
Write-Host "   (aguardando ciclo de audit ~60s)"
Start-Sleep -Seconds 70
kubectl get k8spsprunasnonroot pods-must-run-as-non-root -o jsonpath='{.status.violations}'
Write-Host ""
kubectl delete -f manifests/bad-pod.yaml --ignore-not-found

Write-Host ""
Write-Host "== 4b) Constraint em DENY -> Pod inseguro e REJEITADO"
# Mesma Constraint, so trocando enforcementAction para deny: agora a violacao
# bloqueia a criacao do pod no admission webhook, em vez de so ser reportada.
kubectl apply -f constraints/run-as-nonroot.yaml
Start-Sleep -Seconds 5
kubectl apply -f manifests/bad-pod.yaml 2> err.txt
if ($LASTEXITCODE -eq 0) {
    Stop-WithError "pod inseguro deveria ser negado"
}
Get-Content err.txt

Write-Host ""
Write-Host "== 5) Pod corrigido -> ADMITIDO"
# Mesma Constraint em deny ainda ativa: o pod so passa porque atende a regra
# (ex.: runAsNonRoot: true), provando que o bloqueio anterior foi pela policy.
kubectl apply -f manifests/good-pod.yaml
kubectl get pod secure-pod

Write-Host ""
Write-Host "== 6) Status da constraint"
$yaml = kubectl get constraint pods-must-run-as-non-root -o yaml
$statusLine = ($yaml | Select-String -Pattern '^status:').LineNumber
if ($statusLine) {
    $yaml[($statusLine - 1)..($yaml.Count - 1)]
}

Write-Host ""
Write-Host "Lab 03 OK  (limpe com: .\run.ps1 -Cleanup)"