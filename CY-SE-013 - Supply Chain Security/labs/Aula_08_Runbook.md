# Aula 08 — Compliance Contínuo, Auditoria e Projeto Final

## Objetivo
Integrar Policy as Code, SBOM, assinatura/provenance e evidência de auditoria em um fluxo verificável.

## Pré-requisitos
- Tudo das aulas anteriores: **Docker, OPA, Conftest, Syft, Trivy, Cosign, jq, Node.js, Python** (checklist no fim de [INSTALACAO.md](INSTALACAO.md)).
- **Conta GitHub** com repositório próprio (assinatura keyless e provenance SLSA L3 dependem do GitHub Actions + OIDC). Secrets `DT_URL` e `DT_API_KEY` apontando para o Dependency-Track da Aula 05.
- Opcional: cluster kind + **helm** (`winget install Helm.Helm` / `brew install helm`) para instalar o policy-controller e demonstrar o bloqueio no admission.
- Opcional: **GitHub CLI** (`winget install GitHub.cli` / `brew install gh`) para o relatório mensal.

## Passos
1. Confirme os critérios: policies Rego testadas, SBOM CycloneDX e SPDX, análise, assinatura keyless e provenance.
2. Execute o pipeline do commit ao artefato; guarde logs, digests e evidências de cada controle.
3. Demonstre cenário adversarial: imagem sem assinatura ou policy violada deve falhar no gate.
4. Gere relatório de conformidade com estado de assinatura/provenance e indicadores do projeto.
5. Mapeie evidências a NIST SSDF, SLSA e ISO 27001; identifique lacunas sem alegar certificação.
6. Apresente o fluxo em 15 minutos: contexto, demo, bloqueio, evidência, framework e perguntas.

## Verificação de sucesso
O pipeline produz evidência rastreável, o cenário inválido é bloqueado e a equipe consegue explicar o vínculo entre controles, artefatos e framework.

## Entregáveis
Repositório funcional, README de decisões, evidências, relatório/KPIs e apresentação final.

## Resposta e teste automatizado
`respostas/Aula_08/api-pagamentos/` — projeto completo: 5 policies Rego com 20 testes, `release.yml` (gates → SBOM → Trivy → Dependency-Track → `cosign sign/attest` → provenance SLSA L3), `verify.yml`, `ClusterImagePolicy`, Deployment hardenizado, `gera_relatorio.sh`, `consulta_dt.py` e README com mapeamento NIST SSDF / SLSA / ISO 27001 / PCI DSS. `bash respostas/Aula_08/run.sh` valida localmente tudo que não depende do GitHub, incluindo os cenários adversariais.