#!/usr/bin/env bash
# Lab 04 — gerar e analisar SBOMs. Requer: docker (daemon ativo), syft, trivy, jq, conftest.
set -euo pipefail
cd "$(dirname "$0")"
IMAGE=nginx:1.27.0

echo "== 1) Gerar SBOMs com Syft (CycloneDX + SPDX)"
# Mesma imagem, dois formatos de SBOM: mais adiante comparamos a estrutura de
# cada um para mostrar que "SBOM" nao e um formato unico, e sim uma familia deles.
syft "$IMAGE" -o cyclonedx-json=sbom.cdx.json -o spdx-json=sbom.spdx.json -q

echo; echo "== 2) Gerar SBOM com Trivy (CycloneDX)"
# --timeout maior: na 1a execucao o Trivy baixa o banco de vulnerabilidades (~60 MB)
trivy image --timeout 15m --format cyclonedx --output sbom-trivy.cdx.json -q "$IMAGE"

echo; echo "== 3) Inspecionar  (Syft inclui type=file no CycloneDX; filtramos pacotes)"
# Sem esse filtro, a contagem de "componentes" ficaria inflada com arquivos
# individuais do sistema de arquivos da imagem, que nao sao pacotes de software.
PKG='.components[] | select(.type != "file")'
echo -n "componentes CycloneDX (syft, total):   "; jq '.components | length' sbom.cdx.json
echo -n "componentes CycloneDX (syft, pacotes): "; jq "[$PKG] | length" sbom.cdx.json
echo -n "componentes CycloneDX (trivy):         "; jq '.components | length' sbom-trivy.cdx.json
echo -n "packages SPDX (syft):                  "; jq '.packages | length' sbom.spdx.json
echo "primeiros 5 pacotes:"; jq -r "$PKG | \"\(.name) \(.version)\"" sbom.cdx.json | sort | head -5
echo "licencas unicas (10 primeiras):"; jq -r "$PKG | .licenses[]?.license.id // empty" sbom.cdx.json | sort -u | head -10

echo; echo "== 4) Comparar campos de um componente nos dois formatos (mesmo pacote, comparacao justa)"
# Usamos o mesmo pacote (por nome) nos dois formatos: pegar [0] de cada lista de
# forma independente seria tendencioso, pois a 1a entrada de 'packages' no SPDX
# costuma ser o pacote raiz (a propria imagem), nao um componente de biblioteca.
SAMPLE_NAME=$(jq -r "[$PKG][0].name" sbom.cdx.json)
echo "Pacote de exemplo: $SAMPLE_NAME"
echo "CycloneDX:"; jq --arg n "$SAMPLE_NAME" "[$PKG] | map(select(.name == \$n)) | .[0] | keys" sbom.cdx.json
echo "SPDX:";      jq --arg n "$SAMPLE_NAME" '.packages | map(select(.name == $n)) | .[0] | keys' sbom.spdx.json

echo; echo "== 5) Politica Rego sobre o SBOM (licencas proibidas + PURL)"
# conftest aplica policies/sbom.rego direto no SBOM: "deny" bloqueia (licenca
# proibida ou PURL ausente) e "warn" so avisa (pacote sem licenca declarada).
# `|| true` evita que o script pare aqui: queremos ver a saida mesmo se houver deny.
conftest test sbom.cdx.json --policy policies/ || true

echo; echo "== 6) Testes unitarios da politica"
# Valida a logica Rego em si (policies/sbom_test.rego), independente do SBOM
# real gerado acima — garante que a policy continua correta se for alterada.
opa test policies/ -v

echo; echo "Lab 04 OK"
