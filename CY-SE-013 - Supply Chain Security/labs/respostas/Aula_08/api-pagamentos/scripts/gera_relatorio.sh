#!/usr/bin/env bash
# Relatorio mensal de conformidade NIST SSDF PS.2.1 / PS.3.1 (assinatura + provenance por release).
# Requer: gh (autenticado), cosign, jq.  Variaveis: REPO (org/repo), MES (YYYY-MM, default = mes atual)
set -euo pipefail
REPO="${REPO:-empresa/api-pagamentos}"
MES="${MES:-$(date +%Y-%m)}"
ID="^https://github.com/${REPO%%/*}/"
ISS=https://token.actions.githubusercontent.com
OUT="relatorios/$MES"; mkdir -p "$OUT"

gh release list --repo "$REPO" --limit 100 --json tagName,publishedAt \
  | jq --arg m "$MES" '[.[] | select(.publishedAt | startswith($m))]' > "$OUT/releases.json"

echo "tag,assinatura,provenance,sbom,verificado_em" > "$OUT/conformidade.csv"
jq -r '.[].tagName' "$OUT/releases.json" | while read -r TAG; do
  IMG="ghcr.io/$REPO:$TAG"
  SIG=$(cosign verify "$IMG" --certificate-identity-regexp "$ID" --certificate-oidc-issuer "$ISS" >/dev/null 2>&1 && echo sim || echo nao)
  PROV=$(cosign verify-attestation "$IMG" --type slsaprovenance \
         --certificate-identity-regexp '^https://github.com/slsa-framework/slsa-github-generator/' \
         --certificate-oidc-issuer "$ISS" >/dev/null 2>&1 && echo sim || echo nao)
  SBOM=$(cosign verify-attestation "$IMG" --type cyclonedx --certificate-identity-regexp "$ID" --certificate-oidc-issuer "$ISS" >/dev/null 2>&1 && echo sim || echo nao)
  echo "$TAG,$SIG,$PROV,$SBOM,$(date -u +%FT%TZ)" >> "$OUT/conformidade.csv"
done

TOTAL=$(($(wc -l < "$OUT/conformidade.csv") - 1))
OK=$(grep -c ',sim,sim,sim,' "$OUT/conformidade.csv" || true)
echo "Releases em $MES: $TOTAL | 100% conformes: $OK"
echo "Relatorio: $OUT/conformidade.csv"
