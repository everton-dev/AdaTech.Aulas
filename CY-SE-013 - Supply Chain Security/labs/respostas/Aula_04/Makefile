IMAGE ?= nginx:1.27.0
PKG := .components[] | select(.type != "file")

.PHONY: all sbom-cdx sbom-spdx sbom-trivy inspect compare policy test clean

all: sbom-cdx sbom-spdx sbom-trivy inspect compare policy test

sbom-cdx:
	syft $(IMAGE) -o cyclonedx-json=sbom.cdx.json

sbom-spdx:
	syft $(IMAGE) -o spdx-json=sbom.spdx.json

sbom-trivy:
	trivy image --timeout 15m --format cyclonedx --output sbom-trivy.cdx.json $(IMAGE)

inspect:
	@echo -n "componentes CycloneDX (syft, total):   "; jq '.components | length' sbom.cdx.json
	@echo -n "componentes CycloneDX (syft, pacotes): "; jq '[$(PKG)] | length' sbom.cdx.json
	@echo -n "componentes CycloneDX (trivy):         "; jq '.components | length' sbom-trivy.cdx.json
	@echo -n "packages SPDX (syft):                  "; jq '.packages | length' sbom.spdx.json
	@echo "primeiros 5 pacotes:"; jq -r '$(PKG) | "\(.name) \(.version)"' sbom.cdx.json | sort | head -5
	@echo "licencas unicas (10 primeiras):"; jq -r '$(PKG) | .licenses[]?.license.id // empty' sbom.cdx.json | sort -u | head -10

# Compara os campos do MESMO pacote (por nome) em CycloneDX e SPDX. Pegar o
# indice [0] de cada formato de forma independente seria tendencioso, pois a
# 1a entrada de 'packages' no SPDX costuma ser o pacote raiz (a propria
# imagem), nao um componente de biblioteca.
compare:
	@NAME=$$(jq -r '[$(PKG)][0].name' sbom.cdx.json); \
	echo "Pacote de exemplo: $$NAME"; \
	echo "CycloneDX:"; jq --arg n "$$NAME" '[$(PKG)] | map(select(.name == $$n)) | .[0] | keys' sbom.cdx.json; \
	echo "SPDX:";      jq --arg n "$$NAME" '.packages | map(select(.name == $$n)) | .[0] | keys' sbom.spdx.json

policy:
	conftest test sbom.cdx.json --policy policies/ || true

test:
	opa test policies/ -v

clean:
	rm -f sbom*.json
