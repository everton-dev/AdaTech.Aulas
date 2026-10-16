# Guia de instalação das ferramentas do módulo

Todas as ferramentas são binários únicos ou imagens Docker. Escolha o seu sistema e siga a coluna correspondente. Depois de instalar, rode a **verificação** no fim de cada bloco.

> **Windows:** os laboratórios usam scripts `bash`. Use o **Git Bash** (vem com o Git for Windows) ou o **WSL 2 + Ubuntu** (`wsl --install`). Se usar WSL, instale as ferramentas *dentro* do Ubuntu seguindo a coluna Linux.

---

## Docker (Aulas 3, 4, 5, 7, 8)

| Sistema | Como instalar |
|---|---|
| Windows | Baixe o Docker Desktop em <https://www.docker.com/products/docker-desktop/>, instale e reinicie. Abra o Docker Desktop e aguarde o ícone ficar verde. Em *Settings → Resources* reserve **≥ 6 GB de RAM** (a Aula 5 exige 4 GB só para o Dependency-Track). |
| macOS | Docker Desktop (mesmo link) ou `brew install --cask docker`. |
| Linux (Ubuntu/Debian) | `curl -fsSL https://get.docker.com | sh && sudo usermod -aG docker $USER` — faça logout/login. |

```bash
docker run --rm hello-world     # deve imprimir "Hello from Docker!"
docker compose version          # Compose v2 (vem no Docker Desktop)
```

## OPA e Conftest (Aulas 1, 2, 4, 8)

| Sistema | OPA | Conftest |
|---|---|---|
| Windows (PowerShell) | `winget install OpenPolicyAgent.OPA` **ou** baixe `opa_windows_amd64.exe` em <https://github.com/open-policy-agent/opa/releases/latest>, renomeie para `opa.exe` e coloque em uma pasta do `PATH` (ex.: `C:\tools`). | Baixe `conftest_<versão>_Windows_x86_64.zip` em <https://github.com/open-policy-agent/conftest/releases/latest>, extraia `conftest.exe` para a mesma pasta. |
| macOS | `brew install opa` | `brew install conftest` |
| Linux | `OPA_LATEST=$(curl -s https://api.github.com/repos/open-policy-agent/opa/releases/latest \| grep tag_name \| cut -d '"' -f4); curl -L -o opa "https://github.com/open-policy-agent/opa/releases/download/${OPA_LATEST}/opa_linux_amd64_static" && chmod +x opa && sudo mv opa /usr/local/bin/` | `LATEST=$(curl -s https://api.github.com/repos/open-policy-agent/conftest/releases/latest \| grep tag_name \| cut -d '"' -f4); curl -LO "https://github.com/open-policy-agent/conftest/releases/download/${LATEST}/conftest_${LATEST#v}_Linux_x86_64.tar.gz" && tar xzf conftest_*.tar.gz && sudo mv conftest /usr/local/bin/` |

> Para adicionar `C:\tools` ao PATH no Windows: *Iniciar → "Editar variáveis de ambiente da conta" → Path → Novo → `C:\tools`*. Abra um terminal novo depois.

```bash
opa version        # Version: 1.x
conftest --version # Conftest: 0.7x
```

**Atenção — Rego v1:** o OPA 1.x usa a sintaxe v1 por padrão (`deny contains msg if { ... }`). Os exemplos do material usam a sintaxe antiga (`deny[msg] { ... }`). Ou escreva no formato novo (como nas respostas), ou rode `opa eval --v0-compatible` / `conftest ... --rego-version v0`.

## jq (Aulas 4, 5, 7, 8)

| Sistema | Como instalar |
|---|---|
| Windows | `winget install jqlang.jq` **ou** baixe `jq-windows-amd64.exe` em <https://github.com/jqlang/jq/releases/latest>, renomeie para `jq.exe` e coloque no `PATH`. |
| macOS | `brew install jq` |
| Linux | `sudo apt install jq` |

## kind + kubectl (Aulas 3, 7, 8)

| Sistema | kubectl | kind |
|---|---|---|
| Windows | `winget install Kubernetes.kubectl` (ou `choco install kubernetes-cli`) | `winget install Kubernetes.kind` (ou `choco install kind`) |
| macOS | `brew install kubectl` | `brew install kind` |
| Linux | `curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && sudo install kubectl /usr/local/bin/` | `curl -Lo kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 && chmod +x kind && sudo mv kind /usr/local/bin/` |

```bash
kind create cluster --name teste && kubectl get nodes && kind delete cluster --name teste
```

## Syft e Trivy (Aulas 4, 5, 7, 8)

| Sistema | Syft | Trivy |
|---|---|---|
| Windows | Baixe `syft_<versão>_windows_amd64.zip` em <https://github.com/anchore/syft/releases/latest>, extraia `syft.exe` para o `PATH`. | `winget install AquaSecurity.Trivy` **ou** baixe `trivy_<versão>_windows-64bit.zip` em <https://github.com/aquasecurity/trivy/releases/latest>. |
| macOS | `brew install syft` | `brew install trivy` |
| Linux | `curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh \| sh -s -- -b /usr/local/bin` | `curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \| sh -s -- -b /usr/local/bin` |

```bash
syft version
trivy --version
# A 1ª execução do Trivy baixa o banco de vulnerabilidades (~60 MB) — pode levar vários minutos.
# Use --timeout 15m na primeira vez.
```

## Cosign (Aulas 7, 8)

| Sistema | Como instalar |
|---|---|
| Windows | `winget install sigstore.cosign` **ou** baixe `cosign-windows-amd64.exe` em <https://github.com/sigstore/cosign/releases/latest>, renomeie para `cosign.exe`. |
| macOS | `brew install cosign` |
| Linux | `curl -LO https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64 && sudo install cosign-linux-amd64 /usr/local/bin/cosign` |

```bash
cosign version   # GitVersion: v3.x
```

> **Cosign 3.x:** para assinar com chave local **sem** publicar no Rekor público use `--tlog-upload=false --use-signing-config=false`; para verificar, `--insecure-ignore-tlog`. Em produção, prefira keyless (OIDC) — aí nenhuma dessas flags é necessária.

## Node.js e npm (Aulas 6, 8)

| Sistema | Como instalar |
|---|---|
| Windows | `winget install OpenJS.NodeJS.LTS` ou instalador em <https://nodejs.org/> (LTS 20+). |
| macOS | `brew install node@20` |
| Linux | `curl -fsSL https://deb.nodesource.com/setup_20.x \| sudo -E bash - && sudo apt install -y nodejs` |

```bash
node --version && npm --version   # npm >= 9 (tem `npm audit signatures`)
```

## Python 3 + pip (Aulas 5, 6, 8)

| Sistema | Como instalar |
|---|---|
| Windows | `winget install Python.Python.3.12` ou <https://www.python.org/downloads/> (marque *Add python.exe to PATH*). |
| macOS | `brew install python@3.12` |
| Linux | `sudo apt install python3 python3-venv python3-pip` |

```bash
python --version          # (ou python3)
python -m pip --version
```

## GitHub CLI — opcional (Aula 8, relatório)

| Sistema | Como instalar |
|---|---|
| Windows | `winget install GitHub.cli` |
| macOS | `brew install gh` |
| Linux | <https://github.com/cli/cli/blob/trunk/docs/install_linux.md> |

`gh auth login` antes de usar.

---

## Checklist rápido

```bash
for t in docker opa conftest jq kubectl kind syft trivy cosign node npm python git; do
  command -v $t >/dev/null && echo "OK      $t" || echo "FALTA   $t"
done
```
