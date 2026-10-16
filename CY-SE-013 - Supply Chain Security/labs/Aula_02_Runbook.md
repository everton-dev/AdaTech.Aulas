# Aula 02 — Linguagem Rego e Escrita de Políticas

## Objetivo
Escrever, testar e aplicar políticas Rego a Dockerfiles e manifests Kubernetes.

## Pré-requisitos
- OPA e Conftest instalados (mesmo setup da Aula 01; veja [INSTALACAO.md](INSTALACAO.md)).
- Familiaridade com JSON, YAML e Dockerfiles.
- Opcional: `jq` para ler a cobertura (`opa test --coverage --format=json | jq .coverage`). Windows: `winget install jqlang.jq`; macOS: `brew install jq`; Linux: `sudo apt install jq`.

```bash
opa version && conftest --version && jq --version
```

## Passos
1. Crie `policies/docker/` e `policies/kubernetes/`.
2. Escreva a política Docker: allowlist de imagens-base, bloqueio de `USER root` e exigência de instrução `USER`.
3. Valide um Dockerfile seguro e depois altere a base para `ubuntu:latest` e o usuário para root; compare os resultados.
4. Escreva a política Kubernetes para bloquear UID 0 e exigir limite de memória.
5. Valide um Deployment seguro e remova o limite ou use `runAsUser: 0` para provocar uma violação.
6. Adicione testes para cenários permitidos e negados e execute `opa test policies/ -v`.

## Verificação de sucesso
Os casos seguros passam, os inseguros são negados com mensagens acionáveis e os testes OPA passam.

## Entregáveis
Políticas Docker/Kubernetes, manifestos de teste e arquivos `*_test.rego`.

## Resposta e teste automatizado
`respostas/Aula_02/` — `bash respostas/Aula_02/run.sh` valida Dockerfile e Deployment (casos seguro e inseguro) e roda `opa test` com cobertura (8 testes, 100 %).