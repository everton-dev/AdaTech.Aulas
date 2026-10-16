# Aula 04 — SBOM, SPDX e CycloneDX

## Objetivo
Gerar e inspecionar SBOMs nos formatos CycloneDX e SPDX e validar campos de segurança.

## Pré-requisitos
- **Docker** em execução (para que Syft/Trivy baixem a imagem `nginx:1.27.0`).
- **Syft**, **Trivy**, **jq**, **OPA** e **Conftest**. Guia completo em [INSTALACAO.md](INSTALACAO.md). Resumo:

| Sistema | Syft | Trivy |
|---|---|---|
| Windows | Baixe `syft_<versão>_windows_amd64.zip` em <https://github.com/anchore/syft/releases/latest>; extraia `syft.exe` para `C:\tools` | `winget install AquaSecurity.Trivy` |
| macOS | `brew install syft` | `brew install trivy` |
| Linux | `curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh \| sh -s -- -b /usr/local/bin` | `curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \| sh -s -- -b /usr/local/bin` |

```bash
syft version && trivy --version && jq --version
```

> A **primeira execução do Trivy** baixa o banco de vulnerabilidades (~60 MB) e pode demorar vários minutos; use `trivy image --timeout 15m ...`.

## Passos
1. Gere `sbom.cdx.json` (CycloneDX) e `sbom.spdx.json` (SPDX) com Syft.
2. Gere também um CycloneDX com Trivy (`sbom-trivy.cdx.json`) e compare as saídas.
3. Conte componentes, liste versões e licenças com `jq`.
4. Compare os campos de um mesmo componente (pelo nome) nos dois formatos; observe PURL, hashes e relações.
5. Escreva uma política Rego que sinaliza componente sem licença (ausente ou lista vazia), PURL ausente (chave faltante ou string vazia) ou licença proibida.
6. Execute `conftest test sbom.cdx.json --policy policies/` e corrija ou explique cada achado.

## Verificação de sucesso
Os dois formatos são válidos e legíveis; a política identifica dados ausentes ou licenças não permitidas.

## Entregáveis
SBOM CycloneDX, SBOM SPDX, consultas de inspeção e política de validação.

## Resposta e teste automatizado
`respostas/Aula_04/` — `bash respostas/Aula_04/run.sh` (ou `make all`) gera os SBOMs, inspeciona com `jq` e aplica a política. Observação didática: o CycloneDX do Syft inclui entradas `type: file`; a política filtra apenas pacotes. Em `nginx:1.27.0` a política **falha** por pacotes Debian GPL-3 — resultado esperado para discutir allowlist de licenças.