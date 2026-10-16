# Aula 06 — Ataques e Frameworks de Supply Chain Security

## Objetivo
Mapear ameaças por fase da cadeia e aplicar hardening a dependências e ao pipeline.

## Pré-requisitos
- **Node.js 20 LTS / npm ≥ 9** (`npm audit signatures` precisa de npm 9+): Windows `winget install OpenJS.NodeJS.LTS`; macOS `brew install node@20`; Linux `curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install -y nodejs`.
- **Git** (`git --version`).
- **Python 3 + venv** para o exercício com `pip-tools` (`pip install pip-tools` é feito pelo script).
- **Docker** apenas para obter o digest da imagem-base (`docker buildx imagetools inspect node:20-bookworm-slim`).

```bash
node --version && npm --version && python --version
```

## Passos
1. Desenhe as fases source, build e distribution; posicione typosquatting, dependency confusion e build poisoning.
2. Analise SolarWinds, Codecov, `ua-parser-js` e XZ Utils: vetor, impacto e controle que reduziria o risco.
3. Configure lockfile e `.npmrc` com `ignore-scripts=true`, registry esperado e versão exata.
4. Instale com `npm ci --ignore-scripts`; execute `npm audit signatures` e `npm audit --audit-level=high`.
5. Revise o workflow CI: permissões mínimas, ações fixadas por SHA e credenciais efêmeras.
6. Opcional: gere hashes com `pip-compile --generate-hashes` e instale com `pip install --require-hashes`.
7. Mapeie controles selecionados a SLSA e NIST SSDF.

## Verificação de sucesso
O lockfile é usado sem alterações; scripts de instalação são bloqueados; o pipeline falha diante de assinatura ou vulnerabilidade fora da política.

## Entregáveis
Mapa de ameaças, mudanças de hardening e matriz curta de controles SLSA/SSDF.

## Resposta e teste automatizado
`respostas/Aula_06/` — `bash respostas/Aula_06/run.sh` instala com `npm ci --ignore-scripts`, verifica `npm audit signatures` e `npm audit --audit-level=high`, gera `requirements.txt` com hashes (`pip-compile --generate-hashes`) e confere o `FROM` pinado por digest. Mapa de ameaças e matriz SLSA/SSDF em `mapa-de-ameacas.md`; workflow endurecido em `.github/workflows/build-hardened.yml`.