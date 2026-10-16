#!/usr/bin/env bash
# Lab 03 — Gatekeeper em cluster kind. Requer: docker, kind, kubectl.
# Uso: ./run.sh            (cria cluster, instala, testa)
#      ./run.sh --cleanup  (apaga o cluster)
set -euo pipefail
cd "$(dirname "$0")"
CLUSTER=policy-lab
GK_VERSION=v3.18.2

if [[ "${1:-}" == "--cleanup" ]]; then
  kind delete cluster --name "$CLUSTER"; exit 0
fi

echo "== 1) Cluster kind"
kind get clusters | grep -qx "$CLUSTER" || kind create cluster --name "$CLUSTER"
kubectl cluster-info --context "kind-$CLUSTER" >/dev/null

echo; echo "== 2) Instalar Gatekeeper $GK_VERSION"
# Gatekeeper roda como admission webhook: ele intercepta requests ao API server
# e so libera (ou nao) a criacao do recurso depois de avaliar as policies.
kubectl apply -f "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/$GK_VERSION/deploy/gatekeeper.yaml"
kubectl -n gatekeeper-system rollout status deploy/gatekeeper-controller-manager --timeout=180s
kubectl -n gatekeeper-system rollout status deploy/gatekeeper-audit --timeout=180s

echo; echo "== 3) ConstraintTemplate"
# O ConstraintTemplate define a regra em Rego (nao roda nada sozinho); ele gera
# um novo CRD (K8sPSPRunAsNonRoot) que sera usado para instanciar a Constraint.
kubectl apply -f templates/runasnonroot.yaml
# aguarda o CRD gerado pelo template ficar disponivel
for i in $(seq 1 30); do
  kubectl get crd k8spsprunasnonroot.constraints.gatekeeper.sh >/dev/null 2>&1 && break; sleep 2
done

echo; echo "== 4a) Constraint em DRYRUN -> Pod inseguro e ADMITIDO, mas aparece em status.violations"
# dryrun simula o efeito da policy sem bloquear nada: util para medir o impacto
# antes de ligar o enforcement e quebrar workloads existentes em producao.
kubectl apply -f constraints/run-as-nonroot-dryrun.yaml
sleep 5
kubectl apply -f manifests/bad-pod.yaml
echo "   (aguardando ciclo de audit ~60s)"; sleep 70
kubectl get k8spsprunasnonroot pods-must-run-as-non-root -o jsonpath='{.status.violations}' ; echo
kubectl delete -f manifests/bad-pod.yaml --ignore-not-found

echo; echo "== 4b) Constraint em DENY -> Pod inseguro e REJEITADO"
# Mesma Constraint, so trocando enforcementAction para deny: agora a violacao
# bloqueia a criacao do pod no admission webhook, em vez de so ser reportada.
kubectl apply -f constraints/run-as-nonroot.yaml
sleep 5
if kubectl apply -f manifests/bad-pod.yaml 2>err.txt; then
  echo "ERRO: pod inseguro deveria ser negado"; exit 1
fi
cat err.txt

echo; echo "== 5) Pod corrigido -> ADMITIDO"
# Mesma Constraint em deny ainda ativa: o pod so passa porque atende a regra
# (ex.: runAsNonRoot: true), provando que o bloqueio anterior foi pela policy.
kubectl apply -f manifests/good-pod.yaml
kubectl get pod secure-pod

echo; echo "== 6) Status da constraint"
kubectl get constraint pods-must-run-as-non-root -o yaml | sed -n '/^status:/,$p'

echo; echo "Lab 03 OK  (limpe com: ./run.sh --cleanup)"
