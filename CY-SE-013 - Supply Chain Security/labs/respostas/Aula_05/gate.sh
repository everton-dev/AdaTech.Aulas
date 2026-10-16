#!/usr/bin/env bash
# Gate de pipeline: falha (exit 1) se o projeto tiver violacoes de policy com estado FAIL.
# Requer: curl, jq. Variaveis: DT_URL, DT_KEY, PROJECT_NAME, PROJECT_VERSION.
set -euo pipefail
: "${DT_URL:?defina DT_URL (ex.: http://localhost:8081)}"
: "${DT_KEY:?defina DT_KEY (API key do time Automation)}"
PROJECT_NAME="${PROJECT_NAME:-lab-node14}"
PROJECT_VERSION="${PROJECT_VERSION:-baseline}"

PROJECT_UUID=$(curl -sf -H "X-Api-Key: ${DT_KEY}" \
  "${DT_URL}/api/v1/project/lookup?name=${PROJECT_NAME}&version=${PROJECT_VERSION}" | jq -r .uuid)

VIOLATIONS=$(curl -sf -H "X-Api-Key: ${DT_KEY}" \
  "${DT_URL}/api/v1/violation/project/${PROJECT_UUID}" \
  | jq '[.[] | select(.policyCondition.policy.violationState == "FAIL")] | length')

CRITICAL=$(curl -sf -H "X-Api-Key: ${DT_KEY}" \
  "${DT_URL}/api/v1/metrics/project/${PROJECT_UUID}/current" | jq -r '.critical // 0')
CRITICAL=${CRITICAL:-0}

echo "Projeto: ${PROJECT_NAME}@${PROJECT_VERSION} (${PROJECT_UUID})"
echo "CVEs criticas: ${CRITICAL} | Violacoes FAIL: ${VIOLATIONS}"

if [ "${VIOLATIONS}" -gt 0 ]; then
  echo "Pipeline bloqueado: ${VIOLATIONS} violacao(oes) de policy."
  exit 1
fi
echo "Gate aprovado."
