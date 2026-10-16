# Mapa de ameaças e controles — Aula 06

## 1. Fases da cadeia e vetores

| Fase | Vetor | Ativo atacado | Controle | Evidência |
|---|---|---|---|---|
| Origem | Commit malicioso / revisão simbólica | Branch `main` | Branch protection, 2 aprovações, commits assinados (Gitsign) | Config do repo + Rekor |
| Origem | Token Git vazado | Credencial de dev | gitleaks no pre-commit e CI, tokens de escopo mínimo, OIDC | Log do gitleaks |
| Build | Typosquatting (`reqests`) | `npm install` | Lockfile com hash, `save-exact`, npq/Socket antes de adicionar | `package-lock.json` |
| Build | Dependency confusion | Pacote interno `@empresa/*` | Scope privado + `always-auth` no registry interno | `.npmrc` |
| Build | Pacote malicioso (postinstall) | Ambiente de CI | `ignore-scripts=true`, `npm ci` | `.npmrc` + log do CI |
| Build | Build poisoning (SolarWinds) | Toolchain / runner | Runner efêmero, build reprodutível, provenance SLSA | Atestação assinada |
| Build | Cache envenenado | `actions/cache` | Chave = hash do lockfile, ACL, expiração | Workflow |
| Distribuição | Artefato substituído (Codecov) | Registry / script | Hash de bootstrap, assinatura Cosign, verificação no consumo | `cosign verify` |
| Distribuição | Downgrade | Consumidor | Pinning por digest, versão mínima | `FROM ...@sha256` |
| Distribuição | Chave de assinatura roubada | Publisher | Keyless Sigstore (OIDC), Rekor público | Entrada no Rekor |

## 2. Estudos de caso

| Caso | Vetor | Impacto | Sinal de detecção | Lição / controle |
|---|---|---|---|---|
| SolarWinds (2020) | MSBuild injetava DLL; artefato assinado com chave legítima | ~18 mil organizações | Tráfego DNS atípico | Build isolado e reprodutível; provenance verificada no consumo |
| Codecov (2021) | Script bash uploader alterado via credencial da imagem | Secrets de CI exfiltrados por 73 dias | Hash do script divergente | Verificar hash de scripts de terceiros; secrets efêmeros |
| ua-parser-js (2021) | Conta npm sequestrada | Minerador + stealer em 8 mi downloads/semana | Publicação anômala | 2FA no registry, `npm audit signatures`, lockfile |
| XZ Utils (2024) | Mantenedor malicioso; backdoor em tarball de release | sshd comprometido em distros | Latência de 500 ms no SSH | Build a partir do Git, não do tarball; escrutínio de novos mantenedores |

## 3. Mapeamento a frameworks

| Controle implementado | SLSA (Build track) | NIST SSDF |
|---|---|---|
| Lockfile imutável + `npm ci` | L1 (materials rastreáveis) | PW.4.1 |
| `ignore-scripts` | — (hardening de build) | PW.4.4 |
| `npm audit signatures` | L2 (verificação de assinatura) | PS.3.1 |
| `npm audit --audit-level=high` | — | RV.1.1 |
| Actions fixadas por SHA | L2 (builder confiável) | PS.1.1 |
| Runner efêmero GitHub-hosted | L3 (isolamento) | PO.5.1 |
| `FROM` pinado por digest | L1 | PS.3.1 |
| `pip-compile --generate-hashes` | L1 | PW.4.1 |
