# Aula 05 — Análise de SBOM e Gestão de Dependências

## Objetivo
Ingerir um SBOM no Dependency-Track, definir um gate por vulnerabilidade e praticar atualização de dependências.

## Pré-requisitos
- **Docker Desktop com ≥ 6 GB de RAM** (*Settings → Resources*). O Dependency-Track **recusa iniciar com menos de 4 GB de heap** — o `docker-compose.yml` já define `JAVA_OPTIONS=-Xmx4g`. Na 1ª execução ele leva 3–5 min para subir e baixa a base NVD em segundo plano.
- **Docker Compose v2** (`docker compose version`), **Syft**, **curl** e **jq** (ver [INSTALACAO.md](INSTALACAO.md)).
- **Python 3.10+** com `venv` para o `pip-audit`: Windows `winget install Python.Python.3.12` (marque *Add to PATH*); macOS `brew install python@3.12`; Linux `sudo apt install python3 python3-venv`.
- Opcional: repositório GitHub de laboratório para observar o Dependabot.

```bash
docker compose version && syft version && jq --version && python --version
```

## Passos
1. Suba o Dependency-Track com os serviços API e frontend; aguarde a inicialização e troque a senha padrão.
2. Crie uma API key para automação e guarde-a em variável de ambiente, nunca no repositório.
3. **Habilite uma fonte de vulnerabilidades**: em *Administration → Vulnerability Sources → Google OSV* marque ao menos **Alpine** e **npm** e reinicie o apiserver (`docker compose restart apiserver`). Sem isso o DT não correlaciona nada — o espelho NVD por feeds costuma falhar e o OSV vem desligado.
4. Gere um SBOM CycloneDX **1.5** de `node:14-alpine` com Syft (`-o cyclonedx-json@1.5=...`; o DT 4.12 rejeita 1.6/1.7).
5. Envie o SBOM ao endpoint `/api/v1/bom` com `projectName=lab-node14` e `projectVersion=baseline`.
6. No painel, examine componentes e vulnerabilidades; crie uma policy que falha para severidade crítica.
7. Consulte violações pela API e use o resultado para simular a falha do pipeline.
8. Opcional: configure Dependabot e execute `pip-audit --strict` em dependências Python de laboratório.

## Verificação de sucesso
O projeto aparece no painel com componentes correlacionados; a policy crítica gera violação e o gate retorna status de falha.

## Entregáveis
SBOM, evidência da ingestão, configuração da policy e saída do gate.

## Resposta e teste automatizado
`respostas/Aula_05/` — `bash respostas/Aula_05/run.sh` sobe o Dependency-Track, troca a senha padrão, cria a API key via API, ingere o SBOM de `node:14-alpine`, cria a policy *CRITICAL → FAIL*, roda `gate.sh` (exit 1 = bloqueado) e executa `pip-audit`. UI em <http://localhost:8080>. Limpeza: `run.sh --cleanup`.