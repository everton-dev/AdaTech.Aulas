# Demo Aula 04 — Build de uma Function App .NET 10 até a política Rego

## Objetivo

Esta é uma **demonstração conduzida pelo instrutor** em sala, não um exercício de "mão na massa" do aluno. Ela repete o mesmo pipeline do `labs/respostas/Aula_04` (Syft, Trivy, SBOM em CycloneDX/SPDX, gate de política Rego via `conftest`/`opa`), mas sobre uma aplicação própria — uma Azure Function App em .NET 10 — em vez da imagem pública `nginx:1.27.0` usada no lab.

A imagem de runtime do Azure Functions (`mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated10.0`) é baseada em Ubuntu e, assim como o `nginx:1.27.0` do Lab 04, traz dezenas de pacotes Debian com licença GPL-3 (bash, coreutils, tar, sed, grep...). `policies/license/sbom.rego` ganhou uma **exceção específica para aplicações .Net**: quando o SBOM contém pacotes NuGet, GPL-3 encontrado em pacotes de SO (não-NuGet) não é mais tratado como violação — o raciocínio é que esses utilitários estão meramente agregados na imagem, não linkados ao binário .Net, então não acionam copyleft sobre a aplicação. GPL-3 numa dependência NuGet de fato continua bloqueado normalmente. Além disso, esta demo planta de propósito uma dependência NuGet desatualizada e vulnerável (`Newtonsoft.Json` 12.0.1, `CVE-2024-21907`) e usa uma **nova** política Rego (`policies/vuln/`) para bloquear o gate por vulnerabilidade.

## Estrutura

```
app/            Function App .NET 10 (isolated worker) + Dockerfile
policies/
  license/      copia da política de licença/PURL do Lab 04 (deve passar)
  vuln/         política nova: lê vulnerabilities[] do SBOM do Trivy (deve falhar)
run.ps1         script Windows/PowerShell
run.sh          script bash
Makefile        alvos individuais (build, sbom-*, inspect, compare, policy-*, test-*)
```

## Pré-requisitos

Mesmas ferramentas já documentadas em `labs/INSTALACAO.md` para a Aula 4 — Syft, Trivy, jq, conftest, opa —, mais o **SDK .NET 10** local (para a Parte A, que roda `dotnet publish` fora do Docker) e **Docker** (daemon ativo, só necessário a partir da Parte B).

## Como rodar

```powershell
cd "labs/respostas/demos/Aula_04"
./run.ps1
```

ou, em bash:

```bash
cd labs/respostas/demos/Aula_04
./run.sh
```

Também é possível rodar passo a passo via `make publish`, `make sbom-fs-cdx`, `make policy-vuln-fs`, `make build`, `make policy-license`, `make policy-vuln`, etc. (ver `Makefile`).

## O que esperar

A demo tem duas partes, na mesma execução — primeiro sem Docker, depois com Docker:

**Parte A — direto dos arquivos publicados (sem imagem):**
- A0: `dotnet publish` gera `publish/` (os `.dll`/`.exe` da Function App + `AdaSupplyDemo.deps.json`, que lista `Newtonsoft.Json 12.0.1`).
- A1: Syft gera CycloneDX + SPDX com `syft dir:./publish` (sem precisar de uma imagem).
- A2: Trivy gera CycloneDX com `trivy fs ./publish` (scan de filesystem, não de imagem).
- A3: inspeção dos componentes (igual à Parte B, nos arquivos `sbom-fs*`).
- A4 (`policies/vuln/`): **falha de propósito**, já nesta etapa — antes de qualquer imagem existir —, citando `CVE-2024-21907`, `Newtonsoft.Json`, `12.0.1`, severidade `HIGH`. Mostra que a dependência vulnerável é detectável só com os binários publicados.

**Parte B — a mesma análise, agora sobre a imagem Docker:**
- B0: build local da imagem `ada-supply-demo:local`.
- B1–B4: iguais ao Lab 04 (geração e inspeção de SBOM em dois formatos, comparação de campos), agora a partir da imagem.
- B5 (`policies/license/`): **passa**, graças à exceção .Net (GPL-3 de pacotes de SO como bash/coreutils não bloqueia mais uma app .Net) — resta 1 falha residual esperada e inofensiva: o componente `ubuntu` (metadado de release do SO, não um pacote de fato) não tem PURL.
- B6 (`policies/vuln/`): **falha de propósito**, pelo mesmo motivo do passo A4 — confirma que `CVE-2024-21907`/`Newtonsoft.Json`/`12.0.1` se mantém depois de empacotado em imagem. Como o scan de imagem também cobre pacotes de SO (ao contrário do scan de filesystem da Parte A, que só vê o diretório publicado), a lista de falhas é bem maior — inclui várias CVEs HIGH em pacotes Debian como `linux-libc-dev`, além da vulnerabilidade plantada. Importante: `trivy image --format cyclonedx` só popula o array `vulnerabilities` se a flag `--scanners vuln` for passada explicitamente — sem ela, o SBOM lista os componentes normalmente mas o scan de vulnerabilidade é pulado silenciosamente (`run.ps1`/`run.sh`/`Makefile` já passam essa flag).
- Passo 7: `opa test` passa para as duas pastas de política (a lógica Rego está correta; os "deny" de A4/B6 são o SBOM real acusando a vulnerabilidade plantada, não um bug na política).

## Checklist antes da aula

- [ ] Resolver/validar um digest atual para `mcr.microsoft.com/dotnet/sdk:10.0` e `mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated10.0` (`docker inspect --format='{{index .RepoDigests 0}}' <imagem>`), já que o `Dockerfile` fixa por tag, não por digest.
- [ ] Validar que o host de Functions sobe corretamente rodando como `appuser` (usuário não-root definido no `Dockerfile`). Se não subir, remover a linha `USER appuser` — a imagem de runtime do Azure Functions é historicamente testada rodando como root.
- [ ] Rodar `./run.ps1` (ou `./run.sh`) uma vez antes da aula para aquecer o cache do Trivy (baixa o banco de vulnerabilidades na primeira execução, ~60 MB) e confirmar que o fluxo completo funciona na máquina usada em sala.

## Por que isso importa

Mesmo pipeline do Lab 04, achado diferente: a política de licença não é a única forma de um SBOM travar um gate de supply chain — um SBOM enriquecido com dados de vulnerabilidade (como o do Trivy, que inclui `vulnerabilities[]`) permite políticas Rego que bloqueiam por CVE conhecido, não só por metadado de licença. Isso mostra aos alunos que a escolha da ferramenta de geração de SBOM (Syft vs. Trivy) determina quais políticas são possíveis de escrever.
