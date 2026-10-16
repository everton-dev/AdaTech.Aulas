#!/usr/bin/env bash
# Lab 05 — Dependency-Track de ponta a ponta (sobe stack, cria API key via API, ingere SBOM,
# cria policy CRITICAL -> FAIL, roda o gate). Requer: docker compose, syft, curl, jq.
# Uso: ./run.sh | ./run.sh --cleanup
set -euo pipefail
cd "$(dirname "$0")"
export DT_URL="${DT_URL:-http://localhost:8081}"
ADMIN_PASS="${ADMIN_PASS:-LabSupplyChain#2026}"

if [[ "${1:-}" == "--cleanup" ]]; then docker compose down -v; exit 0; fi

echo "== 1) Subir Dependency-Track"
docker compose up -d
echo -n "   aguardando API (1a vez: 3-5 min; baixa NVD em background)"; for i in $(seq 1 120); do
  curl -sf "$DT_URL/api/version" >/dev/null && break; echo -n .; sleep 5; done; echo
curl -sf "$DT_URL/api/version" | jq -c '{application, version}' \
  || { echo "API nao subiu. Veja: docker logs aula_05-apiserver-1  (precisa de 4 GB de heap)"; exit 1; }

echo; echo "== 2) Trocar senha padrao (admin/admin) e obter token"
# Primeiro login forca troca de senha; o endpoint forceChangePassword faz isso sem UI.
curl -s -X POST "$DT_URL/api/v1/user/forceChangePassword" \
  -d "username=admin&password=admin&newPassword=${ADMIN_PASS}&confirmPassword=${ADMIN_PASS}" >/dev/null || true
TOKEN=$(curl -s -X POST "$DT_URL/api/v1/user/login" -d "username=admin&password=${ADMIN_PASS}")
[[ ${#TOKEN} -gt 20 ]] || { echo "falha no login"; exit 1; }

echo; echo "== 3) Gerar API key do time Automation"
TEAM_UUID=$(curl -s -H "Authorization: Bearer $TOKEN" "$DT_URL/api/v1/team" | jq -r '.[] | select(.name=="Automation") | .uuid')
export DT_KEY=$(curl -s -X PUT -H "Authorization: Bearer $TOKEN" "$DT_URL/api/v1/team/$TEAM_UUID/key" | jq -r .key)
# Automation precisa de permissoes de leitura para o gate consultar violacoes/metricas
for p in VIEW_PORTFOLIO VIEW_POLICY_VIOLATION VIEW_VULNERABILITY POLICY_MANAGEMENT PORTFOLIO_MANAGEMENT; do
  curl -s -o /dev/null -X POST -H "Authorization: Bearer $TOKEN" "$DT_URL/api/v1/permission/$p/team/$TEAM_UUID"
done
echo "   DT_KEY=${DT_KEY:0:8}... (guarde em variavel de ambiente, nunca no Git)"

echo; echo "== 3b) Habilitar fonte OSV (NVD feeds costumam falhar/demorar; OSV cobre Alpine e npm, o que o node:14-alpine usa)"
# Em DT 4.12 o espelho OSV so roda no boot ou a cada 24h -> habilita e reinicia o apiserver.
# Restringimos a Alpine+npm para o espelho levar ~2 min (Debian/Maven levam muito mais).
curl -s -o /dev/null -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "$DT_URL/api/v1/configProperty" \
  -d '{"groupName":"vuln-source","propertyName":"google.osv.enabled","propertyValue":"Alpine;npm"}'
docker compose restart apiserver >/dev/null 2>&1
echo -n "   aguardando API"; for i in $(seq 1 60); do curl -sf "$DT_URL/api/version" >/dev/null && break; echo -n .; sleep 5; done; echo
echo -n "   aguardando espelho OSV (Alpine, npm ~2-3 min)"; for i in $(seq 1 60); do
  docker compose logs --since 10m apiserver 2>/dev/null | grep -qE "mirror completed for (npm|Alpine)|Google OSV mirroring complete" && break; echo -n .; sleep 10; done; echo
TOKEN=$(curl -s -X POST "$DT_URL/api/v1/user/login" -d "username=admin&password=${ADMIN_PASS}")

echo; echo "== 4) Gerar SBOM de imagem com CVEs conhecidas (CycloneDX 1.5: DT 4.12 ainda nao le 1.6/1.7)"
syft node:14-alpine -o cyclonedx-json@1.5=node14.cdx.json -q
jq '.components | length' node14.cdx.json

echo; echo "== 5) Enviar SBOM"
UPLOAD=$(curl -s -X POST "$DT_URL/api/v1/bom" -H "X-Api-Key: $DT_KEY" \
  -F autoCreate=true -F projectName=lab-node14 -F projectVersion=baseline -F bom=@node14.cdx.json)
echo "$UPLOAD" | jq -c .
echo "$UPLOAD" | jq -e .token >/dev/null || { echo "upload rejeitado"; exit 1; }
BOM_TOKEN=$(echo "$UPLOAD" | jq -r .token)
echo -n "   aguardando processamento do SBOM"; for i in $(seq 1 60); do
  P=$(curl -s -H "X-Api-Key: $DT_KEY" "$DT_URL/api/v1/event/token/$BOM_TOKEN" | jq -r .processing)
  [[ "$P" == "false" ]] && break; echo -n .; sleep 5; done; echo

echo; echo "== 6) Policy: Severity is CRITICAL -> FAIL (aplicada ao projeto)"
PROJECT_UUID=$(curl -s -H "X-Api-Key: $DT_KEY" "$DT_URL/api/v1/project/lookup?name=lab-node14&version=baseline" | jq -r .uuid)
POLICY_UUID=$(curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "$DT_URL/api/v1/policy" \
  -d '{"name":"Bloqueio de CVE critica","operator":"ANY","violationState":"FAIL"}' | jq -r .uuid)
curl -s -o /dev/null -X PUT -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "$DT_URL/api/v1/policy/$POLICY_UUID/condition" \
  -d '{"subject":"SEVERITY","operator":"IS","value":"CRITICAL"}'
curl -s -o /dev/null -X POST -H "Authorization: Bearer $TOKEN" "$DT_URL/api/v1/policy/$POLICY_UUID/project/$PROJECT_UUID"
# associar a policy ao projeto NAO reavalia nada sozinho (so persiste a associacao).
# o PolicyEngine so roda dentro do upload do SBOM ou de uma analise explicita --
# como a policy foi criada DEPOIS do upload (passo 5), precisamos forcar a reavaliacao agora.
ANALYZE_TOKEN=$(curl -s -X POST -H "Authorization: Bearer $TOKEN" "$DT_URL/api/v1/finding/project/$PROJECT_UUID/analyze" | jq -r .token)
echo -n "   aguardando avaliacao da policy"; for i in $(seq 1 60); do
  # poll no token do evento em vez de 'sleep' fixo: so seguimos quando o DT confirma
  # que terminou de processar, nao quando "achamos" que ja deu tempo
  P=$(curl -s -H "X-Api-Key: $DT_KEY" "$DT_URL/api/v1/event/token/$ANALYZE_TOKEN" | jq -r .processing)
  [[ "$P" == "false" ]] && break; echo -n .; sleep 5; done; echo
# forca recalculo de metricas do projeto para o gate ler numeros atualizados
curl -s -o /dev/null -H "X-Api-Key: $DT_KEY" "$DT_URL/api/v1/metrics/project/$PROJECT_UUID/refresh"; sleep 10

echo; echo "== 7) Gate"
set +e; ./gate.sh; rc=$?; set -e
echo "exit code do gate: $rc  (1 = bloqueado, esperado para node:14-alpine)"

echo; echo "== 8) Auditoria Python local"
# complementa o gate do Dependency-Track: aqui auditamos as dependencias Python
# usadas pelo proprio laboratorio (fora do fluxo de SBOM/DT visto nos passos anteriores)
python -m venv .venv >/dev/null 2>&1 || true
PY=.venv/bin/python; [[ -x $PY ]] || PY=.venv/Scripts/python.exe
$PY -m pip install -q -r python/requirements.txt pip-audit >/dev/null
set +e; $PY -m pip_audit -r python/requirements.txt --strict; set -e

echo; echo "Lab 05 OK — UI: http://localhost:8080 (admin / ${ADMIN_PASS}). Limpe com ./run.sh --cleanup"
