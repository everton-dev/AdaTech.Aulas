# api-pagamentos — Projeto final CY-SE-013

Pipeline de compliance contínuo que integra as três camadas do módulo: **Policy as Code**, **SBOM** e **integridade/procedência**. Cada release deixa evidência verificável do commit ao deploy.

## Estrutura

```
api-pagamentos/
  .github/workflows/release.yml   build → gates Rego → SBOM → scan → sign → attest → provenance SLSA L3
  .github/workflows/verify.yml    verificação de assinatura/SBOM/provenance sob demanda
  policies/rego/                  5 policies: imagem, k8s, pipeline, sbom, licenças
  policies/tests/                 20 testes (opa test) — cenários positivos e negativos
  k8s/policy-controller-policy.yaml  ClusterImagePolicy: só entra imagem assinada + SBOM + provenance
  k8s/deployment.yaml             Deployment hardenizado, imagem por digest
  scripts/gera_relatorio.sh       relatório mensal (CSV) de assinatura/provenance/SBOM por release
  scripts/consulta_dt.py          KPIs do Dependency-Track em CSV
  Dockerfile                      base pinada por digest, npm ci --ignore-scripts, USER node
```

## Como validar localmente

`../run.sh` executa testes das policies, gates sobre Dockerfile/manifest/workflow, build, SBOM, scan e cenários adversariais. Assinatura keyless, provenance SLSA e gate no cluster dependem do repositório estar no GitHub:

1. Crie o repositório, faça push e ajuste `empresa/api-pagamentos` nos arquivos para `<org>/<repo>`.
2. Configure os secrets `DT_URL` e `DT_API_KEY` (Dependency-Track da Aula 05).
3. `git tag v1.0.0 && git push --tags` → acompanhe o workflow `release`.
4. Instale o policy-controller no cluster e aplique `k8s/policy-controller-policy.yaml`:
   ```bash
   helm repo add sigstore https://sigstore.github.io/helm-charts
   helm install policy-controller sigstore/policy-controller -n cosign-system --create-namespace
   kubectl apply -f k8s/policy-controller-policy.yaml
   ```
5. Cenário adversarial (evidência obrigatória na banca):
   ```bash
   kubectl run intruso --image=ghcr.io/<org>/api-pagamentos:fake -n producao
   # Error from server (BadRequest): admission webhook "policy.sigstore.dev" denied the request: no matching signatures
   ```

## Mapeamento de controles a frameworks

| Controle no pipeline | Evidência | NIST SSDF | SLSA | ISO 27001:2022 | PCI DSS 4.0 |
|---|---|---|---|---|---|
| Policies Rego no PR/CI (Dockerfile, manifest, workflow) | logs do job `Policy gate`, `opa test` | PW.4.4, PO.5.1 | — | A.8.26, A.8.28 | 6.2.4 |
| Actions fixadas por SHA, `permissions` mínimas | `pipeline_hardening.rego` | PS.1.1 | Build L2 | A.8.25 | 6.4 |
| SBOM CycloneDX + SPDX por release | artefatos do job + atestação `cyclonedx` | PW.4.1, RV.1.3 | L1 (materials) | A.5.23 | 12.8.1 |
| Policy de licenças sobre o SBOM | `license_policy.rego` | PW.4.1 | — | A.5.32 | — |
| Scan Trivy bloqueante (CRITICAL/HIGH) | atestação `vuln` | RV.1.1 | — | A.8.8, A.8.29 | 6.3.1, 6.2.4 |
| Ingestão no Dependency-Track + policy CRITICAL→FAIL | projeto no DT, `consulta_dt.py` | RV.1.3 | — | A.8.8 | 6.3.1 |
| Assinatura keyless (Cosign + Fulcio + Rekor) | entrada no Rekor, `cosign verify` | PS.2.1 | L2 | A.8.24 | 6.3 |
| Provenance assinada por builder isolado (`slsa-github-generator`) | `cosign verify-attestation --type slsaprovenance` | PS.3.1 | **L3** | A.8.25 | 6.4 |
| Admission: só imagem assinada + SBOM + provenance | saída do webhook `policy.sigstore.dev` | PS.3.1 | L3 (verificação) | A.8.9 | 6.3 |
| Relatório mensal automatizado | `relatorios/<mês>/conformidade.csv` | PO.3.3 | — | A.5.35, A.5.36 | 12.4 |

> Mapear não é certificar: a tabela indica **qual evidência** suporta cada requisito; a conformidade é avaliada pelo auditor.

## KPIs (dashboard)

| KPI | Fonte | Meta |
|---|---|---|
| Releases com SBOM | `gera_relatorio.sh` (coluna `sbom`) | 100 % |
| Releases assinadas + com provenance | `gera_relatorio.sh` | 100 % |
| Projetos sem CVE crítica | `consulta_dt.py` | 100 % |
| Violações de policy (tendência) | `consulta_dt.py` + decision logs | decrescente |
