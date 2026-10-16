#!/usr/bin/env bash
# Executa o Lab 02 de ponta a ponta. Requer: opa, conftest, jq.
set -euo pipefail
cd "$(dirname "$0")"

# imagem na allowlist (approved_base) + usuario nao-root -> nenhuma regra deny casa
printf 'FROM cgr.dev/chainguard/static:latest\nCOPY app /app\nUSER 1001\nCMD ["/app"]\n' > Dockerfile
# imagem ubuntu nao esta na allowlist e USER e root -> duas violacoes independentes
printf 'FROM ubuntu:latest\nCOPY app /app\nUSER root\nCMD ["/app"]\n' > Dockerfile.inseguro

echo "== 1) Dockerfile seguro -> deve PASSAR"
conftest test Dockerfile --policy policies/docker/

echo; echo "== 2) Dockerfile inseguro (ubuntu + root) -> deve FALHAR com 2 violacoes"
# "ubuntu" nao e imagem aprovada (regra de base) e USER root (regra de usuario)
if conftest test Dockerfile.inseguro --parser dockerfile --policy policies/docker/; then
  echo "ERRO: deveria falhar"; exit 1
fi

echo; echo "== 3) Deployment seguro -> deve PASSAR"
# runAsUser != 0, limite de memoria definido e sem segredo em texto plano no env
conftest test manifests/deployment.yaml --policy policies/kubernetes/

echo; echo "== 4) Deployment inseguro (UID 0, sem memoria, token literal) -> deve FALHAR"
# cada problema casa com uma regra deny diferente: runAsUser == 0, limits.memory
# ausente, e variavel com nome sensivel sem vir de secretKeyRef
if conftest test manifests/deployment-insegura.yaml --policy policies/kubernetes/; then
  echo "ERRO: deveria falhar"; exit 1
fi

echo; echo "== 5) Testes unitarios + cobertura"
# cobertura mostra se todas as regras deny das policies tem pelo menos um teste exercitando-as
opa test policies/ -v
if command -v jq >/dev/null 2>&1; then
  opa test policies/ --coverage --format=json | jq '.coverage'
else
  echo "   jq ausente, pulando resumo de cobertura"
fi

echo; echo "Lab 02 OK"
