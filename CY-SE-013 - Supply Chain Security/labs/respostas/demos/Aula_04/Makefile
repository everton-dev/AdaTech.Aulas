IMAGE ?= ada-supply-demo:local
PUBLISH ?= ./publish
PKG := .components[] | select(.type != "file")

.PHONY: all publish sbom-fs-cdx sbom-fs-spdx sbom-fs-trivy inspect-fs policy-vuln-fs \
	build sbom-cdx sbom-spdx sbom-trivy inspect compare policy-license policy-vuln \
	test-license test-vuln clean

all: publish sbom-fs-cdx sbom-fs-spdx sbom-fs-trivy inspect-fs policy-vuln-fs \
	build sbom-cdx sbom-spdx sbom-trivy inspect compare policy-license policy-vuln \
	test-license test-vuln

# --- Parte A: analise direta dos arquivos publicados, sem Docker ---

publish:
	dotnet publish ./app -c Release -o $(PUBLISH)

sbom-fs-cdx:
	syft dir:$(PUBLISH) -o cyclonedx-json=sbom-fs.cdx.json

sbom-fs-spdx:
	syft dir:$(PUBLISH) -o spdx-json=sbom-fs.spdx.json

sbom-fs-trivy:
	trivy fs --timeout 15m --scanners vuln --format cyclonedx --output sbom-fs-trivy.cdx.json $(PUBLISH)

inspect-fs:
	@echo -n "componentes CycloneDX (syft, total):   "; jq '.components | length' sbom-fs.cdx.json
	@echo -n "componentes CycloneDX (syft, pacotes): "; jq '[$(PKG)] | length' sbom-fs.cdx.json
	@echo -n "componentes CycloneDX (trivy):         "; jq '.components | length' sbom-fs-trivy.cdx.json
	@echo -n "packages SPDX (syft):                  "; jq '.packages | length' sbom-fs.spdx.json
	@echo "pacote plantado para a demo (Newtonsoft.Json):"; jq -r '$(PKG) | select(.name | test("newtonsoft"; "i")) | "\(.name) \(.version)"' sbom-fs.cdx.json

# Espera-se FALHAR de proposito, so com base nos arquivos: Newtonsoft.Json 12.0.1 (CVE-2024-21907, HIGH).
policy-vuln-fs:
	conftest test sbom-fs-trivy.cdx.json --policy policies/vuln/ || true

# --- Parte B: mesma analise, agora sobre a imagem Docker da aplicacao ---

build:
	docker build -t $(IMAGE) ./app

sbom-cdx:
	syft $(IMAGE) -o cyclonedx-json=sbom.cdx.json

sbom-spdx:
	syft $(IMAGE) -o spdx-json=sbom.spdx.json

sbom-trivy:
	# --scanners vuln e obrigatorio: sem ele, o CycloneDX gerado lista os componentes
	# mas o array vulnerabilities fica vazio (mesmo com CVEs presentes).
	trivy image --timeout 15m --scanners vuln --format cyclonedx --output sbom-trivy.cdx.json $(IMAGE)

inspect:
	@echo -n "componentes CycloneDX (syft, total):   "; jq '.components | length' sbom.cdx.json
	@echo -n "componentes CycloneDX (syft, pacotes): "; jq '[$(PKG)] | length' sbom.cdx.json
	@echo -n "componentes CycloneDX (trivy):         "; jq '.components | length' sbom-trivy.cdx.json
	@echo -n "packages SPDX (syft):                  "; jq '.packages | length' sbom.spdx.json
	@echo "primeiros 5 pacotes:"; jq -r '$(PKG) | "\(.name) \(.version)"' sbom.cdx.json | sort | head -5
	@echo "pacote plantado para a demo (Newtonsoft.Json):"; jq -r '$(PKG) | select(.name | test("newtonsoft"; "i")) | "\(.name) \(.version)"' sbom.cdx.json

# Compara os campos do MESMO pacote (por nome) em CycloneDX e SPDX. Pegar o
# indice [0] de cada formato de forma independente seria tendencioso, pois a
# 1a entrada de 'packages' no SPDX costuma ser o pacote raiz (a propria
# imagem), nao um componente de biblioteca.
compare:
	@NAME=$$(jq -r '[$(PKG)][0].name' sbom.cdx.json); \
	echo "Pacote de exemplo: $$NAME"; \
	echo "CycloneDX:"; jq --arg n "$$NAME" '[$(PKG)] | map(select(.name == $$n)) | .[0] | keys' sbom.cdx.json; \
	echo "SPDX:";      jq --arg n "$$NAME" '.packages | map(select(.name == $$n)) | .[0] | keys' sbom.spdx.json

# Imagem base e Ubuntu e traz GPL-3 de SO; sbom.rego tem excecao para apps
# .Net (deteccao via PURL NuGet) que isenta GPL-3 de pacotes de SO, mas
# continua negando GPL-3 numa dependencia NuGet. Resta 1 falha esperada e
# inofensiva: componente 'ubuntu' (metadado de release, nao pacote) sem PURL.
policy-license:
	conftest test sbom.cdx.json --policy policies/license/ || true

# Espera-se FALHAR de proposito, pelo mesmo motivo de policy-vuln-fs.
policy-vuln:
	conftest test sbom-trivy.cdx.json --policy policies/vuln/ || true

test-license:
	opa test policies/license/ -v

test-vuln:
	opa test policies/vuln/ -v

clean:
	rm -rf sbom*.json $(PUBLISH)
