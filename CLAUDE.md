# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository shape

This is a Portuguese-language course-materials monorepo for AdaTech courses. There is **no repository-wide build, lint, or test command** — each top-level folder is an independent course, and each `aula-NN` (lesson) subfolder inside it is often a self-contained project with its own stack and toolchain (some are .NET solutions, some are Docker Compose stacks, some are plain slide/exercise folders). Always `cd` into the specific lesson folder before running any build/run command, and check that lesson's own `README.md` first — most non-trivial lessons document their own commands and there are ~300 `README.md` files scattered through the repo.

Top-level courses:
- `AR-NA-002-Arquitetura_de_serviços_e_dados/` — service & data architecture (Docker Compose + SQL Server + Python ETL + Node.js dashboard).
- `CY-SE-013 - Supply Chain Security/` — supply-chain-security labs (Docker, OPA/Conftest, Syft/Trivy, Cosign, SBOM, GitHub Actions security gates).
- `DE-OP-011 Orquestração/` — Kubernetes/container orchestration.
- `DE-OP-014 Serviços para desenvolvedor (Azure)/` — Azure developer services; several `aula-NN/AdaAPI` folders are .NET isolated-worker Azure Functions apps with matching ARM/Zip-Deploy publish profiles.
- `records/` — content the repo owner authored/presented as video lessons for other disciplines (cloud computing, cyber security, data integration, database, system design); not archived student coursework.

## Secrets and credentials convention

`.gitignore` at the repo root blocks `.env*` (except `.env.example`), `*.pem`/`*.key`/`*.pfx`/`id_rsa*`, build output (`bin/`, `obj/`, `node_modules/`, `dist/`, `.venv/`), Terraform state, and archives (`*.zip`/`*.rar`/`*.7z`). Several lessons use hardcoded local-only SQL Server credentials (e.g. `everton` / `@da123*`, `sa` / `Admin@12345`) as defaults inside `docker-compose.yml`/`config.py`/`server.js` — these are intentional throwaway dev credentials documented in the lesson's own README, not leaked secrets; don't "fix" them unless asked. Real cloud credentials (Azure Cosmos/Storage keys, SSH private keys) must never be hardcoded — read them from environment variables instead, following the pattern already used in `records/database/app/CosmosDBSample/CosmosDBSample/Program.cs`.

## AR-NA-002, aula-07 — Geek Store Data Platform

The most fully-built example in the repo: an OLTP → Python ETL → star-schema DWH → dashboard pipeline, run entirely from `AR-NA-002-Arquitetura_de_serviços_e_dados/aula-07/`.

- `docker compose up --build -d` — starts `transaction-db` (SQL Server, `localhost,14331`), `analytics-db` (SQL Server, `localhost,14332`), and `dashboard` (Node/Express on `:8080`).
- `docker compose down -v` — wipes volumes and forces init scripts to rerun from scratch (use when transactional/analytics schemas changed).
- `py transaction-generator/generate_transactions.py --count 50 [--seed 42]` — generates additional synthetic paid orders directly against `transaction-db` (count must be 1–200).
- `py -m pip install -r etl/requirements.txt && py -m etl` — runs the ETL package (`etl/config.py`, `extract.py`, `transform.py`, `load.py`, `pipeline.py`) that reads `transaction_db`, loads `analytics_db` via staging-table `MERGE`s (idempotent — dimensions merge on business keys, `FactOrder` merges on `OrderBusinessKey`, `FactOrderItem` on `OrderItemBusinessKey`), and validates fact counts against source counts at the end.
- Run `db-analytics/truncate_analytics.sql` against `analytics_db` before a full ETL re-load if you need a clean warehouse without recreating containers.
- When running the ETL/dashboard from another container on the `geek-data-network`, use hosts `transaction-db,1433` / `analytics-db,1433` instead of the `localhost` ports.
- The dashboard (`dashboard/server.js`) only reads from `analytics_db` reporting views (`vw_SalesKpis`, `vw_WeekdaySalesFlow`, `vw_ClientPurchasesByAge`, `vw_ProductPerformance`, `vw_PaymentMethodPerformance`) via `/api/report` — it never queries `transaction_db` directly, so changes to the operational schema only need a matching change in the ETL's `transform.py`/`load.py`, not in the dashboard.

## CY-SE-013 — Supply Chain Security labs

Each lesson's reference solution lives in `CY-SE-013 - Supply Chain Security/labs/respostas/Aula_NN/`, paired with a runbook at `labs/Aula_NN_Runbook.md` and tool setup in `labs/INSTALACAO.md`. Lessons build on each other: Rego/OPA policies for Dockerfiles (Aula 1–2) and Kubernetes manifests (Aula 2–3), then SBOM/vuln scanning with Syft/Trivy (Aula 4–5), npm/pip supply-chain checks (Aula 6), and finally Cosign signing + SLSA provenance + a full CI gate (Aula 7–8). Most `respostas/Aula_NN/` folders ship a `run.sh`/`run.ps1` (and Aula 3/8 a `.github/workflows/*.yml`) that validates everything locally, including the adversarial "this must fail the gate" scenarios — run that script rather than re-deriving the policy commands manually. Aula 8 (`respostas/Aula_08/api-pagamentos/`) is the full project: `release.yml` chains gates → SBOM → Trivy → Dependency-Track → `cosign sign/attest` → SLSA L3 provenance, with a separate `verify.yml` and `gera_relatorio.sh` for the compliance report.

## DE-OP-014 — Azure Functions apps (`AdaAPI`)

The `aula-05`–`aula-08` `AdaAPI/AdaAPI/AdaAPI.csproj` projects are .NET 10, isolated-worker Azure Functions (`Microsoft.Azure.Functions.Worker` + `.Extensions.Http.AspNetCore`), each with its own `PublishProfile`/`ServiceDependencies/<name> - Zip Deploy/profile.arm.json` for direct-to-Azure publishing and an ARM template under `scripts/arm-templates/` for infra provisioning. `local.settings.json` is excluded from publish (`CopyToPublishDirectory=Never`) and is where local connection strings/app settings belong — never move those into the ARM templates or source.
