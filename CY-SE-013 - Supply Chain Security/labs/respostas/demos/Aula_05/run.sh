#!/usr/bin/env bash
# Demo Aula 05 — mesmo pipeline do Lab 05 (Dependency-Track), mas sobre a Function App
# .NET 10 propria (app/) em vez do node:14-alpine publico. Sobe a stack, gera o SBOM da
# imagem com Syft, envia pro Dependency-Track e mostra os achados (inclui a dependencia
# plantada Newtonsoft.Json 12.0.1 / CVE-2024-21907). Requer: docker compose, syft, curl, jq.
# Uso: ./run.sh | ./run.sh --cleanup
# Atencao: usa as mesmas portas 8081/8080 do labs/respostas/Aula_05 — nao rode os dois
# stacks ao mesmo tempo (./run.sh --cleanup aqui, ou no outro, antes de trocar).
set -euo pipefail
cd "$(dirname "$0")"
export DT_URL="${DT_URL:-http://localhost:8081}"
ADMIN_PASS="${ADMIN_PASS:-LabSupplyChain#2026}"
PROJECT_NAME="ada-supply-demo"
PROJECT_VERSION="demo"

if [[ "${1:-}" == "--cleanup" ]]; then docker compose down -v; exit 0; fi

echo "== 1) Subir Dependency-Track"
docker compose up -d
echo -n "   aguardando API (1a vez: 3-5 min; baixa NVD em background)"; for i in $(seq 1 120); do
  curl -sf "$DT_URL/api/version" >/dev/null && break; echo -n .; sleep 5; done; echo
curl -sf "$DT_URL/api/version" | jq -c '{application, version}' \
  || { echo "API nao subiu. Veja: docker logs aula_05-apiserver-1  (precisa de 4 GB de heap)"; exit 1; }

echo; echo "== 2) Trocar senha padrao (admin/admin) e obter token"
curl -s -X POST "$DT_URL/api/v1/user/forceChangePassword" \
  -d "username=admin&password=admin&newPassword=${ADMIN_PASS}&confirmPassword=${ADMIN_PASS}" >/dev/null || true
TOKEN=$(curl -s -X POST "$DT_URL/api/v1/user/login" -d "username=admin&password=${ADMIN_PASS}")
[[ ${#TOKEN} -gt 20 ]] || { echo "falha no login"; exit 1; }

echo; echo "== 3) Gerar API key do time Automation"
TEAM_UUID=$(curl -s -H "Authorization: Bearer $TOKEN" "$DT_URL/api/v1/team" | jq -r '.[] | select(.name=="Automation") | .uuid')
export DT_KEY=$(curl -s -X PUT -H "Authorization: Bearer $TOKEN" "$DT_URL/api/v1/team/$TEAM_UUID/key" | jq -r .key)
for p in VIEW_PORTFOLIO VIEW_POLICY_VIOLATION VIEW_VULNERABILITY POLICY_MANAGEMENT PORTFOLIO_MANAGEMENT; do
  curl -s -o /dev/null -X POST -H "Authorization: Bearer $TOKEN" "$DT_URL/api/v1/permission/$p/team/$TEAM_UUID"
done
echo "   DT_KEY=${DT_KEY:0:8}... (guarde em variavel de ambiente, nunca no Git)"

echo; echo "== 3b) Habilitar fonte OSV para NuGet (NVD completo demora demais; OSV cobre o ecossistema NuGet, usado pela Function App)"
curl -s -o /dev/null -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "$DT_URL/api/v1/configProperty" \
  -d '{"groupName":"vuln-source","propertyName":"google.osv.enabled","propertyValue":"NuGet"}'
docker compose restart apiserver >/dev/null 2>&1
echo -n "   aguardando API"; for i in $(seq 1 60); do curl -sf "$DT_URL/api/version" >/dev/null && break; echo -n .; sleep 5; done; echo
echo -n "   aguardando espelho OSV (NuGet ~2-3 min)"; for i in $(seq 1 60); do
  docker compose logs --since 10m apiserver 2>/dev/null | grep -qE "mirror completed for NuGet|Google OSV mirroring complete" && break; echo -n .; sleep 10; done; echo
TOKEN=$(curl -s -X POST "$DT_URL/api/v1/user/login" -d "username=admin&password=${ADMIN_PASS}")

echo; echo "== 4) Build da imagem da Function App (traz Newtonsoft.Json 12.0.1 plantada de proposito)"
docker build -t ${PROJECT_NAME}:local ./app

echo; echo "== 5) Gerar SBOM da imagem (CycloneDX 1.5: DT 4.12 ainda nao le 1.6/1.7)"
syft ${PROJECT_NAME}:local -o cyclonedx-json@1.5=${PROJECT_NAME}.cdx.json -q
jq '.components | length' ${PROJECT_NAME}.cdx.json

echo; echo "== 5b) Sanitizar licencas (o schema CycloneDX 1.5 do DT rejeita 'licenses' com mais de 1 item e 'license.id' fora da lista SPDX dele; o Syft as vezes gera ambos para pacotes NuGet)"
jq '
  def fixentry: if type=="object" and has("license") and (.license|type=="object") and (.license|has("id")) then
      .license |= ({name: .id} + (if has("url") then {url} else {} end))
    else . end;
  walk(
    if type=="object" and has("licenses") and (.licenses|type=="array") then
      .licenses |= (if length>1 then [.[0]] else . end) | .licenses |= map(fixentry)
    else . end
  )' ${PROJECT_NAME}.cdx.json > ${PROJECT_NAME}.fixed.cdx.json

echo; echo "== 6) Enviar SBOM"
UPLOAD=$(curl -s -X POST "$DT_URL/api/v1/bom" -H "X-Api-Key: $DT_KEY" \
  -F autoCreate=true -F projectName=${PROJECT_NAME} -F projectVersion=${PROJECT_VERSION} -F bom=@${PROJECT_NAME}.fixed.cdx.json)
echo "$UPLOAD" | jq -c .
echo "$UPLOAD" | jq -e .token >/dev/null || { echo "upload rejeitado"; exit 1; }
BOM_TOKEN=$(echo "$UPLOAD" | jq -r .token)
echo -n "   aguardando processamento do SBOM"; for i in $(seq 1 60); do
  P=$(curl -s -H "X-Api-Key: $DT_KEY" "$DT_URL/api/v1/event/token/$BOM_TOKEN" | jq -r .processing)
  [[ "$P" == "false" ]] && break; echo -n .; sleep 5; done; echo

echo; echo "== 7) Forcar reanalise de vulnerabilidades (policy OSV so comecou a mirror depois do upload acima nao, mas a reanalise garante achados atualizados)"
PROJECT_UUID=$(curl -s -H "X-Api-Key: $DT_KEY" "$DT_URL/api/v1/project/lookup?name=${PROJECT_NAME}&version=${PROJECT_VERSION}" | jq -r .uuid)
ANALYZE_TOKEN=$(curl -s -X POST -H "Authorization: Bearer $TOKEN" "$DT_URL/api/v1/finding/project/$PROJECT_UUID/analyze" | jq -r .token)
echo -n "   aguardando reanalise"; for i in $(seq 1 60); do
  P=$(curl -s -H "X-Api-Key: $DT_KEY" "$DT_URL/api/v1/event/token/$ANALYZE_TOKEN" | jq -r .processing)
  [[ "$P" == "false" ]] && break; echo -n .; sleep 5; done; echo
curl -s -o /dev/null -H "X-Api-Key: $DT_KEY" "$DT_URL/api/v1/metrics/project/$PROJECT_UUID/refresh"; sleep 10

echo; echo "== 8) Resultados — vulnerabilidades encontradas no projeto ${PROJECT_NAME}:${PROJECT_VERSION}"
curl -s -H "X-Api-Key: $DT_KEY" "$DT_URL/api/v1/finding/project/$PROJECT_UUID" \
  | jq -r '["COMPONENTE","VERSAO","VULNERABILIDADE","SEVERIDADE"], (.[] | [.component.name, .component.version, .vulnerability.vulnId, .vulnerability.severity]) | @tsv' \
  | column -t -s $'\t'

echo; echo "Demo Aula 05 OK — UI: http://localhost:8080 (admin / ${ADMIN_PASS}), projeto '${PROJECT_NAME}'."
echo "Limpe com ./run.sh --cleanup"
