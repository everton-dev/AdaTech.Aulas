# Lab 07 (k8s) - aplica o ClusterImagePolicy keyless num cluster kind e prova a rejeicao.
# Requer: docker, kind, kubectl, helm.  Uso: .\test-k8s-policy.ps1 | .\test-k8s-policy.ps1 -Cleanup
# Obs.: so o caminho de REJEICAO e testavel localmente. O caminho de ACEITACAO exige uma
# assinatura keyless real, feita por um workflow do GitHub Actions rodando dentro do repo
# "github.com/empresa/..." (ver .github/workflows/verify-deploy.yml) - nao da para simular aqui.
param(
    [switch]$Cleanup
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$Cluster = 'policy-keyless-lab'
$Namespace = 'policy-demo'

function Stop-WithError {
    param([string]$Message)
    Write-Host "ERRO: $Message"
    exit 1
}

if ($Cleanup) {
    kind delete cluster --name $Cluster
    exit 0
}

Write-Host "== 1) Cluster kind"
$clusters = kind get clusters
if ($clusters -notcontains $Cluster) {   # so cria se ainda nao existir (permite rodar o script varias vezes)
    kind create cluster --name $Cluster
}
kubectl cluster-info --context "kind-$Cluster" | Out-Null

Write-Host ""
Write-Host "== 2) Instalar o Sigstore policy-controller via Helm"
# policy-controller e o admission webhook que o Sigstore mantem para validar
# assinaturas/atestacoes keyless no momento em que um Pod e criado.
helm repo add sigstore https://sigstore.github.io/helm-charts | Out-Null
helm repo update sigstore | Out-Null
$releaseExists = (helm list -n cosign-system -q) -contains 'policy-controller'   # idempotencia: nao reinstala se ja estiver no cluster
if (-not $releaseExists) {
    helm install policy-controller sigstore/policy-controller -n cosign-system --create-namespace
}
# espera todos os deployments do chart ficarem prontos, sem depender dos nomes exatos
kubectl wait --for=condition=available --timeout=180s deployment --all -n cosign-system

Write-Host ""
Write-Host "== 3) Aplicar o ClusterImagePolicy keyless"
kubectl apply -f k8s/cluster-image-policy-keyless.yaml

Write-Host ""
Write-Host "== 4) Namespace de teste com o enforcement ativado"
# --dry-run=client -o yaml | kubectl apply -f -  =  "cria se nao existir, nao da erro se ja existir"
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
# so namespaces com este label passam pelo admission webhook do policy-controller
kubectl label namespace $Namespace policy.sigstore.dev/include=true --overwrite

Write-Host ""
Write-Host "== 5) Cenario de REJEICAO: imagem sem assinatura keyless valida"
# Continue temporario: com ErrorActionPreference=Stop, redirecionar o stderr de um
# comando nativo que falhar (2> err.txt) trava o script em vez de so gravar no arquivo.
$ErrorActionPreference = 'Continue'
# a tag ":fake" nem precisa existir de verdade: o webhook barra a criacao do Pod
# antes do Kubernetes sequer tentar baixar a imagem
kubectl run intruso --image=ghcr.io/empresa/banner:fake -n $Namespace 2> err.txt
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -eq 0) {   # aqui, exit code 0 (sucesso) e o resultado ERRADO: a policy deveria ter barrado
    Stop-WithError "pod sem assinatura valida deveria ser negado pelo admission webhook"
}
Get-Content err.txt   # mostra a mensagem de recusa do admission webhook

Write-Host ""
Write-Host "== 6) Sobre o caminho de ACEITACAO (nao testavel localmente)"
Write-Host "   A policy so libera imagens assinadas via Fulcio/Rekor por uma identidade real"
Write-Host "   do GitHub Actions (issuer token.actions.githubusercontent.com, repo empresa/*)."
Write-Host "   Isso exige um repositorio de verdade no GitHub; veja .github/workflows/verify-deploy.yml."

kubectl delete namespace $Namespace --ignore-not-found | Out-Null

Write-Host ""
Write-Host "Lab 07 (k8s) OK  (limpe com .\test-k8s-policy.ps1 -Cleanup)"
