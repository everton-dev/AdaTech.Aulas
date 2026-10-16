# Lab 07 - assinar, atestar e verificar uma imagem com Cosign (chave de laboratorio).
# Requer: docker (daemon ativo), cosign, syft.  Uso: .\run.ps1 | .\run.ps1 -Cleanup
# Obs.: usa ConvertFrom-Json/ConvertTo-Json nativos em vez de jq, entao jq nao e necessario aqui.
param(
    [switch]$Cleanup
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$Registry = 'localhost:5000'
$Image = "$Registry/lab/banner:v1"
$env:COSIGN_PASSWORD = if ($env:COSIGN_PASSWORD) { $env:COSIGN_PASSWORD } else { 'lab-password' }  # senha da chave de TESTE
$env:COSIGN_YES = 'true'
# Cosign >= 3: assinatura com chave local, sem publicar no Rekor publico
$OfflineArgs = @('--key', 'cosign.key', '--tlog-upload=false', '--use-signing-config=false')
$VerifyArgs = @('--key', 'cosign.pub', '--insecure-ignore-tlog')

if ($Cleanup) {
    # Continue temporario: com ErrorActionPreference=Stop, redirecionar o stderr de um
    # comando nativo que falhar (2>$null) trava o script em vez de so descartar a saida.
    $ErrorActionPreference = 'Continue'
    docker rm -f lab-registry 2>$null | Out-Null
    $ErrorActionPreference = 'Stop'
    Remove-Item -ErrorAction SilentlyContinue cosign.key, cosign.pub, sbom.cdx.json, *.txt
    exit 0
}

Write-Host "== 1) Registry local + build/push"
$registryRunning = (docker ps --format '{{.Names}}') -contains 'lab-registry'
if (-not $registryRunning) {
    docker run -d --name lab-registry -p 5000:5000 registry:2 | Out-Null
}
Start-Sleep -Seconds 2
docker build -q -t $Image . | Out-Null
docker push -q $Image
$repoDigest = docker inspect --format='{{index .RepoDigests 0}}' $Image
$digest = $repoDigest.Split('@')[1]
$ref = "$Registry/lab/banner@$digest"
Write-Host "   imagem por digest: $ref"

Write-Host ""
Write-Host "== 2) Par de chaves de laboratorio (NUNCA reutilizar em producao)"
if (-not (Test-Path cosign.key)) {
    $ErrorActionPreference = 'Continue'
    cosign generate-key-pair 2>$null | Out-Null
    $ErrorActionPreference = 'Stop'
}
Get-Item cosign.key, cosign.pub

Write-Host ""
Write-Host "== 3) Assinar o DIGEST (tags sao mutaveis) - sem upload ao Rekor publico, pois e chave local"
cosign sign @OfflineArgs $ref
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 4) Verificar assinatura"
(cosign verify @VerifyArgs $ref | ConvertFrom-Json)[0].critical | ConvertTo-Json -Compress

Write-Host ""
Write-Host "== 5) SBOM (Syft) anexado como atestacao CycloneDX"
syft $ref -o cyclonedx-json=sbom.cdx.json -q
cosign attest @OfflineArgs --type cyclonedx --predicate sbom.cdx.json $ref
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 6) Provenance DEMONSTRATIVA anexada como atestacao slsaprovenance"
cosign attest @OfflineArgs --type slsaprovenance1 --predicate provenance.json $ref
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 7) Verificar atestacoes e inspecionar o predicate"
$cyclonedxAttestation = cosign verify-attestation @VerifyArgs --type cyclonedx $ref | ConvertFrom-Json
$cyclonedxPredicate = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($cyclonedxAttestation.payload)) | ConvertFrom-Json
Write-Host "   SBOM: $($cyclonedxPredicate.predicateType) com $($cyclonedxPredicate.predicate.components.Count) componentes"

$provenanceAttestation = cosign verify-attestation @VerifyArgs --type slsaprovenance1 $ref | ConvertFrom-Json
$provenancePredicate = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($provenanceAttestation.payload)) | ConvertFrom-Json
[PSCustomObject]@{
    subject       = $provenancePredicate.subject
    predicateType = $provenancePredicate.predicateType
    builder       = $provenancePredicate.predicate.runDetails.builder.id
} | ConvertTo-Json -Compress

Write-Host ""
Write-Host "== 8) Cenario adversarial: imagem SEM assinatura deve FALHAR na verificacao"
docker tag $Image "$Registry/lab/banner:malicious"
docker push -q "$Registry/lab/banner:malicious"
# a tag aponta para o mesmo digest -> assinatura e encontrada; alteramos o conteudo para gerar outro digest
Set-Content -Path Dockerfile.tampered -NoNewline -Value "FROM alpine:3.20`nRUN echo tampered > /etc/banner`nCMD [`"cat`",`"/etc/banner`"]`n"
docker build -q -f Dockerfile.tampered -t "$Registry/lab/banner:malicious" . | Out-Null
docker push -q "$Registry/lab/banner:malicious"
# Continue temporario: com ErrorActionPreference=Stop, redirecionar o stderr de um
# comando nativo que falhar (2>$null) trava o script em vez de so descartar a saida.
# Este e o caso mais critico: a verificacao abaixo DEVE falhar (imagem adulterada).
$ErrorActionPreference = 'Continue'
cosign verify @VerifyArgs "$Registry/lab/banner:malicious" 2>$null | Out-Null
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -eq 0) {
    Write-Host "ERRO: imagem adulterada nao deveria verificar"
    exit 1
}
Write-Host "   verify falhou para a imagem adulterada (esperado)"

Write-Host ""
Write-Host "== 9) Artefatos gravados no registry (Cosign 3 usa OCI referrers sob a tag sha256-<digest>)"
(Invoke-RestMethod -Uri "http://$Registry/v2/lab/banner/tags/list") | ConvertTo-Json -Compress
# Continue temporario pelo mesmo motivo dos comandos nativos acima (ver comentarios anteriores)
$ErrorActionPreference = 'Continue'
cosign tree $ref 2>$null
$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "Lab 07 OK  (limpe com .\run.ps1 -Cleanup)"
