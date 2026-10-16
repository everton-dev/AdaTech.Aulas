# Relatorio mensal de conformidade NIST SSDF PS.2.1 / PS.3.1 (assinatura + provenance por release).
# Requer: gh (autenticado), cosign.  Variaveis de ambiente: REPO (org/repo), MES (YYYY-MM, default = mes atual)
$ErrorActionPreference = 'Stop'

$Repo = if ($env:REPO) { $env:REPO } else { 'empresa/api-pagamentos' }
$Mes = if ($env:MES) { $env:MES } else { (Get-Date -Format 'yyyy-MM') }
$OrgId = "^https://github.com/$($Repo.Split('/')[0])/"
$Issuer = 'https://token.actions.githubusercontent.com'
$OutDir = "relatorios/$Mes"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Encapsula o padrao "roda o comando, ignora saida, mapeia exit code para sim/nao",
# repetido 3x no script original (assinatura, provenance e SBOM) - DRY
function Test-CosignVerification {
    param([string[]]$Arguments)
    cosign @Arguments *> $null
    if ($LASTEXITCODE -eq 0) { return 'sim' } else { return 'nao' }
}

$releases = gh release list --repo $Repo --limit 100 --json tagName, publishedAt |
    ConvertFrom-Json |
    Where-Object { $_.publishedAt.StartsWith($Mes) }
$releases | ConvertTo-Json | Set-Content "$OutDir/releases.json"

$rows = @('tag,assinatura,provenance,sbom,verificado_em')
foreach ($release in $releases) {
    $tag = $release.tagName
    $image = "ghcr.io/$Repo`:$tag"

    $signature = Test-CosignVerification -Arguments @(
        'verify', $image, '--certificate-identity-regexp', $OrgId, '--certificate-oidc-issuer', $Issuer
    )
    $provenance = Test-CosignVerification -Arguments @(
        'verify-attestation', $image, '--type', 'slsaprovenance',
        '--certificate-identity-regexp', '^https://github.com/slsa-framework/slsa-github-generator/',
        '--certificate-oidc-issuer', $Issuer
    )
    $sbom = Test-CosignVerification -Arguments @(
        'verify-attestation', $image, '--type', 'cyclonedx', '--certificate-identity-regexp', $OrgId, '--certificate-oidc-issuer', $Issuer
    )

    $verifiedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $rows += "$tag,$signature,$provenance,$sbom,$verifiedAt"
}
$rows | Set-Content "$OutDir/conformidade.csv"

$total = $releases.Count
$ok = ($rows | Select-String -Pattern ',sim,sim,sim,').Count
Write-Host "Releases em $Mes`: $total | 100% conformes: $ok"
Write-Host "Relatorio: $OutDir/conformidade.csv"
