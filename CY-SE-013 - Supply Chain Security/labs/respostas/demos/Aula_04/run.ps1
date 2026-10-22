# Demo Aula 04 - mesmo pipeline do Lab 04, agora sobre uma Function App .NET 10
# propria, com uma dependencia vulneravel adicionada de proposito.
# Requer: dotnet SDK, docker (daemon ativo), syft, trivy, jq, conftest, opa.
$ErrorActionPreference = 'Stop'
# Sem isso, no PowerShell 7.3+ um exit code != 0 de comando nativo (ex.: conftest
# com "deny") vira excecao terminante por causa do $ErrorActionPreference acima,
# quebrando o script nos passos de vulnerabilidade mesmo quando o erro e esperado.
$PSNativeCommandUseErrorActionPreference = $false
Set-Location $PSScriptRoot

$Image = 'ada-supply-demo:local'
$Publish = './publish'
# filtro jq reutilizado varias vezes abaixo para nao listar arquivos individuais como se fossem pacotes (DRY)
$PkgFilter = '.components[] | select(.type != "file")'

# ======================================================================
# PARTE A - Analise direta dos arquivos publicados, sem Docker
# ======================================================================

Write-Host "== A0) dotnet publish (gera os .dll/.exe + *.deps.json que serao analisados)"
dotnet publish ./app -c Release -o $Publish
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== A1) Gerar SBOMs com Syft direto do diretorio publicado (sem imagem)"
syft "dir:$Publish" -o cyclonedx-json=sbom-fs.cdx.json -o spdx-json=sbom-fs.spdx.json -q
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== A2) Gerar SBOM com Trivy direto do diretorio publicado (filesystem scan)"
trivy fs --timeout 15m --scanners vuln --format cyclonedx --output sbom-fs-trivy.cdx.json -q $Publish
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== A3) Inspecionar"
Write-Host -NoNewline "componentes CycloneDX (syft, total):   "; jq '.components | length' sbom-fs.cdx.json
Write-Host -NoNewline "componentes CycloneDX (syft, pacotes): "; jq "[$PkgFilter] | length" sbom-fs.cdx.json
Write-Host -NoNewline "componentes CycloneDX (trivy):         "; jq '.components | length' sbom-fs-trivy.cdx.json
Write-Host -NoNewline "packages SPDX (syft):                  "; jq '.packages | length' sbom-fs.spdx.json
Write-Host "pacote plantado para a demo (Newtonsoft.Json):"
$plantedFilter = "$PkgFilter | " + 'select(.name | test("newtonsoft"; "i")) | "\(.name) \(.version)"'
jq -r $plantedFilter sbom-fs.cdx.json

Write-Host ""
Write-Host "== A4) Politica Rego de vulnerabilidade sobre os arquivos publicados (antes de existir qualquer imagem)"
# Espera-se FALHAR de proposito, so com base nos arquivos: Newtonsoft.Json 12.0.1
# tem CVE-2024-21907 (HIGH). Erro ignorado de proposito: queremos ver a saida mesmo com deny.
conftest test sbom-fs-trivy.cdx.json --policy policies/vuln/

# ======================================================================
# PARTE B - Mesma analise, agora sobre a imagem Docker da aplicacao
# ======================================================================

Write-Host ""
Write-Host "== B0) Build da imagem da Function App (.NET 10, isolated worker)"
docker build -q -t $Image ./app
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== B1) Gerar SBOMs com Syft (CycloneDX + SPDX) a partir da imagem"
syft $Image -o cyclonedx-json=sbom.cdx.json -o spdx-json=sbom.spdx.json -q
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== B2) Gerar SBOM com Trivy (CycloneDX) a partir da imagem"
# --timeout maior: na 1a execucao o Trivy baixa o banco de vulnerabilidades (~60 MB)
# --scanners vuln e obrigatorio: sem ele, o CycloneDX gerado lista os componentes mas
# o array vulnerabilities fica vazio (mesmo com CVEs presentes), igual ao A2.
trivy image --timeout 15m --scanners vuln --format cyclonedx --output sbom-trivy.cdx.json -q $Image
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== B3) Inspecionar (Syft inclui type=file no CycloneDX; filtramos pacotes)"
Write-Host -NoNewline "componentes CycloneDX (syft, total):   "; jq '.components | length' sbom.cdx.json
Write-Host -NoNewline "componentes CycloneDX (syft, pacotes): "; jq "[$PkgFilter] | length" sbom.cdx.json
Write-Host -NoNewline "componentes CycloneDX (trivy):         "; jq '.components | length' sbom-trivy.cdx.json
Write-Host -NoNewline "packages SPDX (syft):                  "; jq '.packages | length' sbom.spdx.json

Write-Host "primeiros 5 pacotes:"
$namesFilter = "$PkgFilter | " + '"\(.name) \(.version)"'
jq -r $namesFilter sbom.cdx.json | Sort-Object | Select-Object -First 5

Write-Host "pacote plantado para a demo (Newtonsoft.Json):"
jq -r $plantedFilter sbom.cdx.json

Write-Host ""
Write-Host "== B4) Comparar campos de um componente nos dois formatos (mesmo pacote, comparacao justa)"
$sampleName = jq -r "[$PkgFilter][0].name" sbom.cdx.json
Write-Host "Pacote de exemplo: $sampleName"
$cycloneFilter = "[$PkgFilter] | map(select(.name == " + '$n' + ")) | .[0] | keys"
Write-Host "CycloneDX:"; jq --arg n $sampleName $cycloneFilter sbom.cdx.json
Write-Host "SPDX:";      jq --arg n $sampleName '.packages | map(select(.name == $n)) | .[0] | keys' sbom.spdx.json

Write-Host ""
Write-Host "== B5) Politica Rego de licenca/PURL (reaproveitada do Lab 04)"
# A imagem de runtime do Azure Functions e baseada em Ubuntu e traz dezenas de
# pacotes GPL-3 (bash, coreutils, tar, sed, grep...), igual ao caso do nginx no
# Lab 04. sbom.rego tem uma excecao: quando o SBOM tem pacotes NuGet (ou seja,
# e uma app .Net), GPL-3 de pacotes de SO nao e bloqueado (mera agregacao, nao
# linkado ao binario .Net) — mas GPL-3 numa dependencia NuGet continua negado.
# Resta 1 falha esperada e aceitavel: o componente 'ubuntu' (metadado de
# release do SO, nao um pacote de fato) nao tem PURL. Erro ignorado de
# proposito por causa dessa falha residual conhecida.
conftest test sbom.cdx.json --policy policies/license/

Write-Host ""
Write-Host "== B6) Politica Rego de vulnerabilidade sobre a imagem (confirma o mesmo achado da Parte A)"
# Espera-se FALHAR de proposito, pelo mesmo motivo do passo A4.
conftest test sbom-trivy.cdx.json --policy policies/vuln/

Write-Host ""
Write-Host "== 7) Testes unitarios das politicas"
opa test policies/license/ -v
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
opa test policies/vuln/ -v
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Demo Aula 04 OK"
