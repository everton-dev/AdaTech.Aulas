# AdaTech.Aulas

Repositório pessoal com materiais, exercícios e projetos desenvolvidos durante os cursos da AdaTech. Cada curso vive em uma pasta na raiz, identificada pelo código da disciplina, e é dividido internamente em subpastas `aula-NN` (uma por aula/lição).

Não existe um comando único de build/lint/test para o repositório inteiro — cada `aula-NN` costuma ser um projeto independente, com sua própria stack (.NET, Docker Compose, Python, Node.js, Kubernetes, etc.). Antes de rodar qualquer comando, entre na pasta da aula específica e confira o `README.md` dela, quando existir.

## Estrutura

| Pasta | Curso | Conteúdo |
| --- | --- | --- |
| `AR-NA-002-Arquitetura_de_serviços_e_dados/` | Arquitetura de Serviços e Dados | Docker Compose + SQL Server + ETL em Python + dashboard em Node.js |
| `CY-SE-013 - Supply Chain Security/` | Segurança na Cadeia de Suprimentos | Labs com Docker, OPA/Conftest, Syft/Trivy, Cosign, SBOM e gates de segurança no GitHub Actions |
| `DE-OP-011 Orquestração/` | Orquestração | Kubernetes e orquestração de containers |
| `DE-OP-014 Serviços para desenvolvedor (Azure)/` | Serviços para Desenvolvedor (Azure) | Azure Functions (.NET isolado), ARM templates e deploy via Zip Deploy |
| `records/` | Conteúdo autoral | Material de cursos que ministrei na criação de videoaulas (cloud computing, cyber security, integração de dados, banco de dados, system design) |

### Destaque: Geek Store Data Platform

O exemplo mais completo do repositório fica em `AR-NA-002-Arquitetura_de_serviços_e_dados/aula-07/`: um pipeline OLTP → ETL em Python → data warehouse em esquema estrela → dashboard. Veja o `README.md` da pasta para instruções de execução (`docker compose up --build -d`, geração de transações sintéticas, execução do ETL, etc.).

### Destaque: Supply Chain Security

Em `CY-SE-013 - Supply Chain Security/labs/`, cada aula tem um runbook (`Aula_NN_Runbook.md`), um guia de instalação de ferramentas (`INSTALACAO.md`) e uma solução de referência em `respostas/Aula_NN/`, com scripts `run.sh`/`run.ps1` que validam tudo localmente, incluindo cenários adversariais.

## Convenção de credenciais

Alguns laboratórios usam credenciais fixas de banco de dados apenas para desenvolvimento local (ex.: `everton` / `@da123*`, `sa` / `Admin@12345`), documentadas no próprio README da aula — não são segredos reais. Credenciais de nuvem (chaves do Azure, chaves SSH, etc.) nunca devem ser versionadas; use variáveis de ambiente, conforme o padrão já adotado nos exemplos do repositório.

O `.gitignore` da raiz já bloqueia artefatos de build (`bin/`, `obj/`, `node_modules/`, `dist/`, `.venv/`), estado do Terraform, arquivos compactados e arquivos sensíveis (`.env`, `*.pem`, `*.key`, `*.pfx`, `id_rsa*`).

## Como navegar

1. Identifique o curso pela pasta de nível raiz.
2. Entre na `aula-NN` desejada.
3. Leia o `README.md` local, se existir — a maioria das aulas não triviais documenta seus próprios comandos.
4. Rode os comandos a partir daquela pasta, não da raiz do repositório.
