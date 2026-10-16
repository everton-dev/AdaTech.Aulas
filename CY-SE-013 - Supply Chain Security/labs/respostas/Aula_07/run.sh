#!/usr/bin/env bash
# Lab 07 — assinar, atestar e verificar uma imagem com Cosign (chave de laboratorio).
# Requer: docker (daemon ativo), cosign, syft, jq.  Uso: ./run.sh | ./run.sh --cleanup
set -euo pipefail
cd "$(dirname "$0")"
REG=localhost:5000
IMG=$REG/lab/banner:v1
export COSIGN_PASSWORD="${COSIGN_PASSWORD:-lab-password}"   # senha da chave de TESTE
export COSIGN_YES=true
# Cosign >= 3: assinatura com chave local, sem publicar no Rekor publico
OFFLINE=(--key cosign.key --tlog-upload=false --use-signing-config=false)
VERIFY=(--key cosign.pub --insecure-ignore-tlog)

if [[ "${1:-}" == "--cleanup" ]]; then
  docker rm -f lab-registry >/dev/null 2>&1 || true
  rm -f cosign.key cosign.pub sbom.cdx.json *.txt; exit 0
fi

echo "== 1) Registry local + build/push"
docker ps --format '{{.Names}}' | grep -qx lab-registry || docker run -d --name lab-registry -p 5000:5000 registry:2 >/dev/null
sleep 2
docker build -q -t "$IMG" . >/dev/null
docker push -q "$IMG"
DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "$IMG" | cut -d@ -f2)
REF="$REG/lab/banner@$DIGEST"
echo "   imagem por digest: $REF"

echo; echo "== 2) Par de chaves de laboratorio (NUNCA reutilizar em producao)"
[[ -f cosign.key ]] || cosign generate-key-pair >/dev/null 2>&1
ls cosign.key cosign.pub

echo; echo "== 3) Assinar o DIGEST (tags sao mutaveis) — sem upload ao Rekor publico, pois e chave local"
cosign sign "${OFFLINE[@]}" "$REF"

echo; echo "== 4) Verificar assinatura"
cosign verify "${VERIFY[@]}" "$REF" | jq -c '.[0].critical'

echo; echo "== 5) SBOM (Syft) anexado como atestacao CycloneDX"
syft "$REF" -o cyclonedx-json=sbom.cdx.json -q
cosign attest "${OFFLINE[@]}" --type cyclonedx --predicate sbom.cdx.json "$REF"

echo; echo "== 6) Provenance DEMONSTRATIVA anexada como atestacao slsaprovenance"
cosign attest "${OFFLINE[@]}" --type slsaprovenance1 --predicate provenance.json "$REF"

echo; echo "== 7) Verificar atestacoes e inspecionar o predicate"
cosign verify-attestation "${VERIFY[@]}" --type cyclonedx "$REF" \
  | jq -r '.payload | @base64d | fromjson | "   SBOM: \(.predicateType) com \(.predicate.components | length) componentes"'
cosign verify-attestation "${VERIFY[@]}" --type slsaprovenance1 "$REF" \
  | jq '.payload | @base64d | fromjson | {subject, predicateType, builder: .predicate.runDetails.builder.id}'

echo; echo "== 8) Cenario adversarial: imagem SEM assinatura deve FALHAR na verificacao"
docker tag "$IMG" "$REG/lab/banner:malicious"
docker push -q "$REG/lab/banner:malicious"
# a tag aponta para o mesmo digest -> assinatura e encontrada; alteramos o conteudo para gerar outro digest
printf 'FROM alpine:3.20\nRUN echo tampered > /etc/banner\nCMD ["cat","/etc/banner"]\n' > Dockerfile.tampered
docker build -q -f Dockerfile.tampered -t "$REG/lab/banner:malicious" . >/dev/null
docker push -q "$REG/lab/banner:malicious"
if cosign verify "${VERIFY[@]}" "$REG/lab/banner:malicious" >/dev/null 2>&1; then
  echo "ERRO: imagem adulterada nao deveria verificar"; exit 1
fi
echo "   verify falhou para a imagem adulterada (esperado)"

echo; echo "== 9) Artefatos gravados no registry (Cosign 3 usa OCI referrers sob a tag sha256-<digest>)"
curl -s "http://$REG/v2/lab/banner/tags/list" | jq .
cosign tree "$REF" 2>/dev/null || true

echo; echo "Lab 07 OK  (limpe com ./run.sh --cleanup)"
