# Aula 03 — Enforcement com OPA Gatekeeper

## Objetivo
Aplicar uma política de admissão em Kubernetes e observar a diferença entre `dryrun`, `warn` e `deny`.

## Pré-requisitos
- **Docker** em execução (Docker Desktop no Windows/macOS; `curl -fsSL https://get.docker.com | sh` no Linux). Teste: `docker run --rm hello-world`.
- **kubectl** e **kind** (guia completo em [INSTALACAO.md](INSTALACAO.md)):

| Sistema | kubectl | kind |
|---|---|---|
| Windows | `winget install Kubernetes.kubectl` | `winget install Kubernetes.kind` |
| macOS | `brew install kubectl` | `brew install kind` |
| Linux | `curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && sudo install kubectl /usr/local/bin/` | `curl -Lo kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && chmod +x kind && sudo mv kind /usr/local/bin/` |

```bash
kind version && kubectl version --client
```

- O **Gatekeeper** é instalado dentro do cluster, no passo 2 (um único `kubectl apply`). Reserve ~2 GB de RAM para o Docker.

## Passos
1. Crie o cluster local `policy-lab` e confirme o acesso com `kubectl cluster-info`.
2. Instale Gatekeeper e aguarde os pods no namespace `gatekeeper-system` ficarem prontos.
3. Aplique uma `ConstraintTemplate` que exige `runAsNonRoot: true`.
4. Aplique a Constraint inicialmente em `dryrun`; examine o impacto e as exceções.
5. Mude para `deny` e tente criar um Pod sem `securityContext`.
6. Corrija o Pod com `runAsNonRoot: true` e UID não privilegiado; reaplique.
7. Consulte `status.violations` e discuta a integração do gate no CI.

## Verificação de sucesso
O Pod inseguro é rejeitado em `deny`; o Pod corrigido é admitido; violações aparecem no audit quando aplicável.

## Entregáveis
ConstraintTemplate, Constraint, manifests inseguro/seguro e evidência do bloqueio.

## Resposta e teste automatizado
`respostas/Aula_03/` — `bash respostas/Aula_03/run.sh` cria o cluster, instala o Gatekeeper, demonstra `dryrun` (violação em `status.violations`) e `deny` (Pod rejeitado), e admite o Pod corrigido. Inclui `.github/workflows/policy.yml`. Limpeza: `run.sh --cleanup`.