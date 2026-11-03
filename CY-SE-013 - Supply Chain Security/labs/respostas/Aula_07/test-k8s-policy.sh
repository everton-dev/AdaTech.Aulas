#!/usr/bin/env bash
# Lab 07 (k8s) - aplica o ClusterImagePolicy keyless num cluster kind e prova a rejeicao.
# Requer: docker, kind, kubectl, helm.
# Uso: ./test-k8s-policy.sh            (cria cluster, instala, testa)
#      ./test-k8s-policy.sh --cleanup  (apaga o cluster)
# Obs.: so o caminho de REJEICAO e testavel localmente. O caminho de ACEITACAO exige uma
# assinatura keyless real, feita por um workflow do GitHub Actions rodando dentro do repo
# "github.com/empresa/..." (ver .github/workflows/verify-deploy.yml) - nao da para simular aqui.
set -euo pipefail
cd "$(dirname "$0")"
CLUSTER=policy-keyless-lab
NAMESPACE=policy-demo

if [[ "${1:-}" == "--cleanup" ]]; then
  kind delete cluster --name "$CLUSTER"; exit 0
fi

echo "== 1) Cluster kind"
kind get clusters | grep -qx "$CLUSTER" || kind create cluster --name "$CLUSTER"
kubectl cluster-info --context "kind-$CLUSTER" >/dev/null

echo; echo "== 2) Instalar o Sigstore policy-controller via Helm"
# policy-controller e o admission webhook que o Sigstore mantem para validar
# assinaturas/atestacoes keyless no momento em que um Pod e criado.
helm repo add sigstore https://sigstore.github.io/helm-charts >/dev/null
helm repo update sigstore >/dev/null
helm list -n cosign-system -q | grep -qx policy-controller || \
  helm install policy-controller sigstore/policy-controller -n cosign-system --create-namespace
# espera todos os deployments do chart ficarem prontos, sem depender dos nomes exatos
kubectl wait --for=condition=available --timeout=180s deployment --all -n cosign-system

echo; echo "== 3) Aplicar o ClusterImagePolicy keyless"
kubectl apply -f k8s/cluster-image-policy-keyless.yaml

echo; echo "== 4) Namespace de teste com o enforcement ativado"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$NAMESPACE" policy.sigstore.dev/include=true --overwrite

echo; echo "== 5) Cenario de REJEICAO: imagem sem assinatura keyless valida"
if kubectl run intruso --image=ghcr.io/empresa/banner:fake -n "$NAMESPACE" 2>err.txt; then
  echo "ERRO: pod sem assinatura valida deveria ser negado pelo admission webhook"; exit 1
fi
cat err.txt

echo; echo "== 6) Sobre o caminho de ACEITACAO (nao testavel localmente)"
echo "   A policy so libera imagens assinadas via Fulcio/Rekor por uma identidade real"
echo "   do GitHub Actions (issuer token.actions.githubusercontent.com, repo empresa/*)."
echo "   Isso exige um repositorio de verdade no GitHub; veja .github/workflows/verify-deploy.yml."

kubectl delete namespace "$NAMESPACE" --ignore-not-found >/dev/null

echo; echo "Lab 07 (k8s) OK  (limpe com: ./test-k8s-policy.sh --cleanup)"
