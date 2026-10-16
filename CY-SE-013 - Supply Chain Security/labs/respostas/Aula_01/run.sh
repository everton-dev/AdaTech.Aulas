#!/usr/bin/env bash
# Executa o Lab 01 de ponta a ponta. Requer: opa, conftest.
set -euo pipefail
cd "$(dirname "$0")"

# a policy so tem uma regra que casa com este input (User == "root"),
# entao o resultado esperado e exatamente 1 violacao, nunca mais que isso
echo "== 1) Input inseguro (root) -> deve retornar 1 violacao"
opa eval --format pretty \
  --data policies/docker/security.rego \
  --input inputs/image_root.json \
  "data.docker.security.deny"

COUNT_ROOT=$(opa eval --format raw \
  --data policies/docker/security.rego \
  --input inputs/image_root.json \
  "count(data.docker.security.deny)")
if [ "$COUNT_ROOT" != "1" ]; then
  echo "ERRO: esperado 1 violacao para input root, obtido $COUNT_ROOT"; exit 1
fi

echo; echo "== 2) Input corrigido (UID 1001) -> deve retornar conjunto vazio"
# User != "root" e != null, logo nenhuma das duas regras deny dispara
opa eval --format pretty \
  --data policies/docker/security.rego \
  --input inputs/image_ok.json \
  "data.docker.security.deny"

COUNT_OK=$(opa eval --format raw \
  --data policies/docker/security.rego \
  --input inputs/image_ok.json \
  "count(data.docker.security.deny)")
if [ "$COUNT_OK" != "0" ]; then
  echo "ERRO: esperado 0 violacoes para input corrigido, obtido $COUNT_OK"; exit 1
fi

echo; echo "== 3) Dockerfile inseguro via Conftest -> deve FALHAR (exit != 0)"
# aqui o Conftest parseia o Dockerfile de verdade (nao um JSON de exemplo);
# se "conftest test" tiver sucesso (exit 0) e porque a policy NAO pegou o problema
if conftest test Dockerfile --policy policies/dockerfile.rego; then
  echo "ERRO: Dockerfile inseguro deveria falhar"; exit 1
fi

echo; echo "== 4) Dockerfile corrigido via Conftest -> deve PASSAR"
# USER nao-root definido -> nenhuma regra deny casa, Conftest retorna sucesso
conftest test Dockerfile.ok --parser dockerfile --policy policies/dockerfile.rego

echo; echo "== 5) Testes unitarios da politica"
# valida a logica Rego isoladamente (sem depender de Dockerfile/Conftest)
opa test policies/ -v

echo; echo "Lab 01 OK"
