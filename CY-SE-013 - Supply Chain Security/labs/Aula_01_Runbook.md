# Aula 01 — Policy as Code e Compliance Automatizado

## Objetivo
Criar uma política Rego que bloqueia imagens Docker executadas como root e validá-la com OPA e Conftest.

## Pré-requisitos
- Terminal **bash** (Git Bash no Windows, ou WSL/Ubuntu) e um editor de texto (VS Code com a extensão *Open Policy Agent*).
- **OPA** e **Conftest** instalados. Guia completo em [INSTALACAO.md](INSTALACAO.md). Resumo:

| Sistema | OPA | Conftest |
|---|---|---|
| Windows | `winget install OpenPolicyAgent.OPA` ou baixe `opa_windows_amd64.exe` em <https://github.com/open-policy-agent/opa/releases/latest>, renomeie para `opa.exe` e coloque em `C:\tools` (adicione ao PATH) | Baixe `conftest_<versão>_Windows_x86_64.zip` em <https://github.com/open-policy-agent/conftest/releases/latest> e extraia `conftest.exe` para `C:\tools` |
| macOS | `brew install opa` | `brew install conftest` |
| Linux | `curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static && chmod +x opa && sudo mv opa /usr/local/bin/` | veja INSTALACAO.md |

```bash
opa version        # esperado: Version: 1.x
conftest --version # esperado: Conftest: 0.7x
```

> **Rego v1:** o OPA 1.x exige `deny contains msg if { ... }` (sintaxe v1). Os exemplos do material em `deny[msg] { ... }` só rodam com `opa eval --v0-compatible`. As respostas já estão no formato v1.

## Passos
1. Crie `policies/docker/security.rego` com regras `deny` para `User == "root"` e para usuário ausente.
2. Crie `inputs/image_root.json` e avalie com `opa eval --data policies/docker/security.rego --input inputs/image_root.json "data.docker.security.deny"`.
3. Troque o usuário para `1001` em `inputs/image_ok.json` e confirme que não há violações.
4. Crie um Dockerfile inseguro com `USER root` e uma política Conftest para a instrução `USER`.
5. Execute `conftest test Dockerfile --policy policies/dockerfile.rego`.
6. Discuta como transformar o resultado em gate obrigatório no pipeline.

## Verificação de sucesso
OPA reporta a violação para root; Conftest reprova o Dockerfile inseguro; o input corrigido passa.

## Entregáveis
Política Rego, dois inputs JSON, Dockerfile de teste e registro das saídas dos comandos.

## Resposta e teste automatizado
`respostas/Aula_01/` — execute `bash respostas/Aula_01/run.sh` para validar todos os passos (inclui `opa test`).