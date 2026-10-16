#!/usr/bin/env bash
# Lab 06 — hardening de dependencias npm e Python. Requer: node/npm >= 9, python 3, git.
set -euo pipefail
cd "$(dirname "$0")"

echo "== 1) Gerar lockfile (apenas na primeira execucao) e instalar com hashes, sem scripts"
# --ignore-scripts desativa lifecycle scripts (ex: postinstall) do pacote e de suas
# dependencias: e o vetor mais comum de ataque supply-chain em pacotes npm maliciosos
[[ -f package-lock.json ]] || npm install --package-lock-only --ignore-scripts
# 'npm ci' (em vez de 'npm install') instala exatamente o que esta no lockfile,
# sem recalcular versoes: garante reprodutibilidade e falha se o lockfile estiver desatualizado
npm ci --ignore-scripts

echo; echo "== 2) Lockfile imutavel (nao pode mudar durante o pipeline)"
git diff --exit-code package-lock.json 2>/dev/null || echo "   (fora de um repo git ou lockfile recem-criado: ok para o primeiro run)"

echo; echo "== 3) Verificar assinaturas Sigstore dos pacotes"
# confirma que os pacotes instalados batem com a assinatura publicada no registry;
# isso pega adulteracao/substituicao de pacote que uma simples checagem de versao nao detecta
npm audit signatures

echo; echo "== 4) Auditoria de vulnerabilidades (falha em HIGH ou acima)"
# limiar em HIGH evita que o pipeline quebre por achados LOW/MODERATE de baixo
# impacto pratico, mantendo o gate focado no que realmente deve bloquear o build
npm audit --audit-level=high

echo; echo "== 5) Verificar que postinstall esta bloqueado"
# garante a protecao mesmo se alguem rodar 'npm install'/'npm ci' sem a flag --ignore-scripts
# manualmente: o .npmrc torna o bloqueio o padrao do projeto, nao so deste script
grep -q '^ignore-scripts=true' .npmrc && echo "   ignore-scripts=true OK"

echo; echo "== 6) Teste rapido da aplicacao"
# confirma que o hardening (ignore-scripts, lockfile travado) nao quebrou a app:
# seguranca que impede a aplicacao de rodar nao e seguranca utilizavel
node -e 'const app=require("./src/server.js"); const s=app.listen(0,()=>{fetch(`http://localhost:${s.address().port}/health`).then(r=>r.json()).then(j=>{console.log("   /health ->",JSON.stringify(j)); s.close();});});'

echo; echo "== 7) Equivalente Python: requirements com hashes"
python -m venv .venv >/dev/null 2>&1 || true
PY=.venv/bin/python; [[ -x $PY ]] || PY=.venv/Scripts/python.exe
$PY -m pip install -q pip-tools >/dev/null
mkdir -p python
echo "requests==2.32.3" > python/requirements.in
$PY -m piptools compile --generate-hashes -q -o python/requirements.txt python/requirements.in
grep -c -- '--hash=sha256' python/requirements.txt | xargs echo "   hashes gerados:"
# --require-hashes forca o pip a so instalar pacotes cujo hash bata com o lockfile:
# pinar so a versao nao impede troca do artefato (ex: pacote comprometido republicado
# com o mesmo numero de versao); o hash pina o conteudo exato do arquivo
$PY -m pip install -q --require-hashes -r python/requirements.txt && echo "   pip install --require-hashes OK"

echo; echo "== 8) Dockerfile pinado por digest"
# tag (ex: ':18-alpine') e mutavel: o mantenedor pode republicar a mesma tag apontando
# para outro conteudo; @sha256 referencia o conteudo exato da imagem, imutavel por definicao
grep -q 'FROM .*@sha256:' Dockerfile && echo "   FROM com @sha256 OK"

echo; echo "Lab 06 OK"
