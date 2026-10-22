#!/usr/bin/env bash
# Demo Aula 04 — mesmo pipeline do Lab 04, agora sobre uma Function App .NET 10
# propria, com uma dependencia vulneravel adicionada de proposito.
# Requer: dotnet SDK, docker (daemon ativo), syft, trivy, jq, conftest, opa.
set -euo pipefail
cd "$(dirname "$0")"
IMAGE=ada-supply-demo:local
PUBLISH=./publish
PKG='.components[] | select(.type != "file")'

# ======================================================================
# PARTE A — Analise direta dos arquivos publicados, sem Docker
# ======================================================================

echo "== A0) dotnet publish (gera os .dll/.exe + *.deps.json que serao analisados)"
dotnet publish ./app -c Release -o "$PUBLISH"

echo; echo "== A1) Gerar SBOMs com Syft direto do diretorio publicado (sem imagem)"
syft "dir:$PUBLISH" -o cyclonedx-json=sbom-fs.cdx.json -o spdx-json=sbom-fs.spdx.json -q

echo; echo "== A2) Gerar SBOM com Trivy direto do diretorio publicado (filesystem scan)"
trivy fs --timeout 15m --scanners vuln --format cyclonedx --output sbom-fs-trivy.cdx.json -q "$PUBLISH"

echo; echo "== A3) Inspecionar"
echo -n "componentes CycloneDX (syft, total):   "; jq '.components | length' sbom-fs.cdx.json
echo -n "componentes CycloneDX (syft, pacotes): "; jq "[$PKG] | length" sbom-fs.cdx.json
echo -n "componentes CycloneDX (trivy):         "; jq '.components | length' sbom-fs-trivy.cdx.json
echo -n "packages SPDX (syft):                  "; jq '.packages | length' sbom-fs.spdx.json
echo "pacote plantado para a demo (Newtonsoft.Json):"
jq -r "$PKG | select(.name | test(\"newtonsoft\"; \"i\")) | \"\(.name) \(.version)\"" sbom-fs.cdx.json

echo; echo "== A4) Politica Rego de vulnerabilidade sobre os arquivos publicados (antes de existir qualquer imagem)"
# Espera-se FALHAR de proposito: Newtonsoft.Json 12.0.1 tem CVE-2024-21907 (HIGH).
# `|| true` evita que o script pare aqui: queremos ver a saida mesmo com deny.
conftest test sbom-fs-trivy.cdx.json --policy policies/vuln/ || true

# ======================================================================
# PARTE B — Mesma analise, agora sobre a imagem Docker da aplicacao
# ======================================================================

echo; echo "== B0) Build da imagem da Function App (.NET 10, isolated worker)"
docker build -q -t "$IMAGE" ./app

echo; echo "== B1) Gerar SBOMs com Syft (CycloneDX + SPDX) a partir da imagem"
syft "$IMAGE" -o cyclonedx-json=sbom.cdx.json -o spdx-json=sbom.spdx.json -q

echo; echo "== B2) Gerar SBOM com Trivy (CycloneDX) a partir da imagem"
# --scanners vuln e obrigatorio: sem ele, o CycloneDX gerado lista os componentes mas
# o array vulnerabilities fica vazio (mesmo com CVEs presentes), igual ao A2.
trivy image --timeout 15m --scanners vuln --format cyclonedx --output sbom-trivy.cdx.json -q "$IMAGE"

echo; echo "== B3) Inspecionar (Syft inclui type=file no CycloneDX; filtramos pacotes)"
echo -n "componentes CycloneDX (syft, total):   "; jq '.components | length' sbom.cdx.json
echo -n "componentes CycloneDX (syft, pacotes): "; jq "[$PKG] | length" sbom.cdx.json
echo -n "componentes CycloneDX (trivy):         "; jq '.components | length' sbom-trivy.cdx.json
echo -n "packages SPDX (syft):                  "; jq '.packages | length' sbom.spdx.json
echo "primeiros 5 pacotes:"; jq -r "$PKG | \"\(.name) \(.version)\"" sbom.cdx.json | sort | head -5
echo "pacote plantado para a demo (Newtonsoft.Json):"
jq -r "$PKG | select(.name | test(\"newtonsoft\"; \"i\")) | \"\(.name) \(.version)\"" sbom.cdx.json

echo; echo "== B4) Comparar campos de um componente nos dois formatos (mesmo pacote, comparacao justa)"
SAMPLE_NAME=$(jq -r "[$PKG][0].name" sbom.cdx.json)
echo "Pacote de exemplo: $SAMPLE_NAME"
echo "CycloneDX:"; jq --arg n "$SAMPLE_NAME" "[$PKG] | map(select(.name == \$n)) | .[0] | keys" sbom.cdx.json
echo "SPDX:";      jq --arg n "$SAMPLE_NAME" '.packages | map(select(.name == $n)) | .[0] | keys' sbom.spdx.json

echo; echo "== B5) Politica Rego de licenca/PURL (reaproveitada do Lab 04)"
# A imagem de runtime do Azure Functions e baseada em Ubuntu e traz dezenas de
# pacotes GPL-3 (bash, coreutils, tar, sed, grep...), igual ao caso do nginx no
# Lab 04. sbom.rego tem uma excecao: quando o SBOM tem pacotes NuGet (ou seja,
# e uma app .Net), GPL-3 de pacotes de SO nao e bloqueado (mera agregacao, nao
# linkado ao binario .Net) — mas GPL-3 numa dependencia NuGet continua negado.
# Resta 1 falha esperada e aceitavel: o componente 'ubuntu' (metadado de
# release do SO, nao um pacote de fato) nao tem PURL. `|| true` evita que o
# script pare aqui por causa dessa falha residual conhecida.
conftest test sbom.cdx.json --policy policies/license/ || true

echo; echo "== B6) Politica Rego de vulnerabilidade sobre a imagem (confirma o mesmo achado da Parte A)"
# Espera-se FALHAR de proposito, pelo mesmo motivo do passo A4.
conftest test sbom-trivy.cdx.json --policy policies/vuln/ || true

echo; echo "== 7) Testes unitarios das politicas"
opa test policies/license/ -v
opa test policies/vuln/ -v

echo; echo "Demo Aula 04 OK"
