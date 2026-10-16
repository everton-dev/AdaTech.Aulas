# Respostas dos laboratórios — CY-SE-013 Supply Chain Security

Cada pasta `Aula_NN/` contém a solução completa do laboratório correspondente e um `run.sh` que executa e valida todos os passos (testado em Windows 11 + Git Bash + Docker Desktop, outubro/2026).

| Aula | Pasta | O que o `run.sh` prova | Dependências |
|---|---|---|---|
| 01 | `Aula_01/` | OPA nega root / aceita UID 1001; Conftest reprova Dockerfile inseguro; `opa test` 3/3 | opa, conftest |
| 02 | `Aula_02/` | Políticas Docker + Kubernetes, casos seguro/inseguro, `opa test` 8/8 com 100 % de cobertura | opa, conftest, jq |
| 03 | `Aula_03/` | kind + Gatekeeper: `dryrun` registra violação, `deny` rejeita Pod, Pod corrigido é admitido | docker, kind, kubectl |
| 04 | `Aula_04/` | SBOM CycloneDX/SPDX (Syft) e Trivy, inspeção com jq, política de licenças/PURL, `opa test` 5/5 | docker, syft, trivy, jq, conftest |
| 05 | `Aula_05/` | Dependency-Track via Compose, API key, ingestão, policy CRITICAL→FAIL, gate via API, pip-audit | docker compose, syft, jq, python |
| 06 | `Aula_06/` | `npm ci --ignore-scripts`, `npm audit signatures`, audit HIGH, pip-tools com hashes, FROM por digest | node/npm, python, docker |
| 07 | `Aula_07/` | Registry local, `cosign sign` no digest, atestações SBOM + SLSA v1, verificação, imagem adulterada falha | docker, cosign, syft, jq |
| 08 | `Aula_08/api-pagamentos/` | 5 policies / 20 testes, gates sobre Dockerfile, manifest, workflow e SBOM, cenários adversariais | tudo acima |

Instalação de ferramentas: [../INSTALACAO.md](../INSTALACAO.md).

## Como executar

```bash
# dentro de labs/respostas, com as ferramentas no PATH
bash Aula_01/run.sh
bash Aula_03/run.sh           # cria cluster kind; limpe com: bash Aula_03/run.sh --cleanup
bash Aula_05/run.sh           # sobe Dependency-Track (precisa de 4 GB de heap); --cleanup derruba
bash Aula_07/run.sh           # sobe registry local; --cleanup remove
```

## Observações verificadas durante os testes

- **OPA 1.x usa Rego v1**: `deny contains msg if { ... }`. A sintaxe do material (`deny[msg] { ... }`) exige `--v0-compatible`. Todas as respostas estão em v1.
- **Syft gera CycloneDX 1.7**; o Dependency-Track 4.12 só aceita até 1.5 → use `-o cyclonedx-json@1.5=...`.
- **Syft inclui `type: file`** no CycloneDX de imagens; políticas e consultas filtram apenas pacotes.
- **Dependency-Track recusa iniciar com < 4 GB de heap** (`JAVA_OPTIONS=-Xmx4g` no compose).
- **Sem fonte de vulnerabilidades, o DT não acha CVE nenhuma**: o espelho NVD por feeds falhou repetidamente (HTTP 403/503 do nist.gov) e o OSV vem desabilitado. O script habilita OSV para `Alpine;npm` e reinicia o apiserver (o espelho só roda no boot ou a cada 24 h). Resultado com `node:14-alpine`: 56 vulnerabilidades, 2 críticas, 2 violações FAIL → gate bloqueia.
- **Trivy** baixa o banco de vulnerabilidades na 1ª execução; use `--timeout 15m`.
- **Cosign 3.x** com chave local: `--tlog-upload=false --use-signing-config=false` (sign/attest) e `--insecure-ignore-tlog` (verify). Use `--type slsaprovenance1` para predicate SLSA v1.
- `express@4.21.2` tem CVE HIGH em `path-to-regexp`; as respostas usam `4.22.3` para o `npm audit --audit-level=high` passar.
