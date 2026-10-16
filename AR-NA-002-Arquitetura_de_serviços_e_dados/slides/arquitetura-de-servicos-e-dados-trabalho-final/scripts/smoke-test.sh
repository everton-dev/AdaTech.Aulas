#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://localhost}"

curl --fail --silent --show-error "$BASE_URL/health" | grep --quiet "ok"

CREATED="$(curl --fail --silent --show-error \
  --request POST \
  --header "Content-Type: application/json" \
  --data '{"name":"Produto smoke test"}' \
  "$BASE_URL/api/products")"
PRODUCT_ID="$(printf '%s' "$CREATED" | sed -n 's/.*"id":\([0-9][0-9]*\).*/\1/p')"

test -n "$PRODUCT_ID"

curl --fail --silent --show-error \
  --request PUT \
  --header "Content-Type: application/json" \
  --data '{"name":"Produto validado"}' \
  "$BASE_URL/api/products/$PRODUCT_ID" | grep --quiet "Produto validado"

curl --fail --silent --show-error --request DELETE "$BASE_URL/api/products/$PRODUCT_ID"
curl --fail --silent --show-error "$BASE_URL/" | grep --quiet "Stockroom"

echo "Smoke test concluido: proxy, frontend e CRUD estao operacionais."