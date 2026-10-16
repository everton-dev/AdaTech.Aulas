# Lab 04 - gerar e analisar SBOMs. Requer: docker (daemon ativo), syft, trivy, jq, conftest, opa.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$Image = 'nginx:1.27.0'
# filtro jq reutilizado varias vezes abaixo para nao listar arquivos individuais como se fossem pacotes (DRY)
$PkgFilter = '.components[] | select(.type != "file")'

Write-Host "== 1) Gerar SBOMs com Syft (CycloneDX + SPDX)"
# Mesma imagem, dois formatos de SBOM: mais adiante comparamos a estrutura de
# cada um para mostrar que "SBOM" nao e um formato unico, e sim uma familia deles.
syft $Image -o cyclonedx-json=sbom.cdx.json -o spdx-json=sbom.spdx.json -q
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 2) Gerar SBOM com Trivy (CycloneDX)"
# --timeout maior: na 1a execucao o Trivy baixa o banco de vulnerabilidades (~60 MB)
trivy image --timeout 15m --format cyclonedx --output sbom-trivy.cdx.json -q $Image
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 3) Inspecionar (Syft inclui type=file no CycloneDX; filtramos pacotes)"
# Sem esse filtro, a contagem de "componentes" ficaria inflada com arquivos
# individuais do sistema de arquivos da imagem, que nao sao pacotes de software.
Write-Host -NoNewline "componentes CycloneDX (syft, total):   "; jq '.components | length' sbom.cdx.json
Write-Host -NoNewline "componentes CycloneDX (syft, pacotes): "; jq "[$PkgFilter] | length" sbom.cdx.json
Write-Host -NoNewline "componentes CycloneDX (trivy):         "; jq '.components | length' sbom-trivy.cdx.json
Write-Host -NoNewline "packages SPDX (syft):                  "; jq '.packages | length' sbom.spdx.json

Write-Host "primeiros 5 pacotes:"
$namesFilter = "$PkgFilter | " + '"\(.name) \(.version)"'
jq -r $namesFilter sbom.cdx.json | Sort-Object | Select-Object -First 5

Write-Host "licencas unicas (10 primeiras):"
jq -r "$PkgFilter | .licenses[]?.license.id // empty" sbom.cdx.json | Sort-Object -Unique | Select-Object -First 10

Write-Host ""
Write-Host "== 4) Comparar campos de um componente nos dois formatos (mesmo pacote, comparacao justa)"
# Usamos o mesmo pacote (por nome) nos dois formatos: pegar [0] de cada lista de
# forma independente seria tendencioso, pois a 1a entrada de 'packages' no SPDX
# costuma ser o pacote raiz (a propria imagem), nao um componente de biblioteca.
$sampleName = jq -r "[$PkgFilter][0].name" sbom.cdx.json
Write-Host "Pacote de exemplo: $sampleName"

# usa $n (variavel do jq, nao do PowerShell) via --arg, por isso fica em string de aspas simples
$cycloneFilter = "[$PkgFilter] | map(select(.name == " + '$n' + ")) | .[0] | keys"
Write-Host "CycloneDX:"; jq --arg n $sampleName $cycloneFilter sbom.cdx.json
Write-Host "SPDX:";      jq --arg n $sampleName '.packages | map(select(.name == $n)) | .[0] | keys' sbom.spdx.json

Write-Host ""
Write-Host "== 5) Politica Rego sobre o SBOM (licencas proibidas + PURL)"
# conftest aplica policies/sbom.rego direto no SBOM: "deny" bloqueia (licenca
# proibida ou PURL ausente) e "warn" so avisa (pacote sem licenca declarada).
# erro ignorado de proposito: queremos ver a saida mesmo se houver deny.
conftest test sbom.cdx.json --policy policies/

Write-Host ""
Write-Host "== 6) Testes unitarios da politica"
# Valida a logica Rego em si (policies/sbom_test.rego), independente do SBOM
# real gerado acima - garante que a policy continua correta se for alterada.
opa test policies/ -v
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Lab 04 OK"
