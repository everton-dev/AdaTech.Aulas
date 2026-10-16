# Lab 08 - valida localmente tudo o que o pipeline release.yml valida (sem precisar do GitHub).
# Requer: opa, conftest, syft, trivy, docker, node/npm.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot 'api-pagamentos')

Write-Host "== 1) Testes unitarios das 5 policies"
opa test policies/ -v | Select-Object -Last 3
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 2) Gate de imagem: Dockerfile"
conftest test Dockerfile --policy policies/rego/image_baseline.rego --namespace supply.image
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 3) Gate de deploy: manifest Kubernetes"
conftest test k8s/deployment.yaml --policy policies/rego/k8s_deployment.rego --namespace supply.k8s
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 4) Gate do proprio pipeline (actions por SHA, permissions)"
# O pipeline CI tambem e tratado como artefato a validar: actions de terceiros
# devem estar fixadas por SHA (tag mutavel = risco de supply chain) e os jobs
# devem pedir so as permissions de que precisam (menos superficie se vazar token).
conftest test .github/workflows/release.yml --policy policies/rego/pipeline_hardening.rego --namespace supply.pipeline
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
conftest test .github/workflows/verify.yml --policy policies/rego/pipeline_hardening.rego --namespace supply.pipeline
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 5) Build local + SBOM + gates de SBOM"
if (-not (Test-Path package-lock.json)) {
    npm install --package-lock-only --ignore-scripts | Out-Null
}
docker build -q -t api-pagamentos:local . | Out-Null
# Gera o SBOM em dois formatos padrao (CycloneDX e SPDX) a partir da imagem ja
# construida, para os gates abaixo avaliarem o que realmente foi para o build.
syft api-pagamentos:local -o cyclonedx-json=sbom.cdx.json -o spdx-json=sbom.spdx.json -q
conftest test sbom.cdx.json --policy policies/rego/sbom_required.rego --namespace supply.sbom
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
# Licenca proibida so bloqueia em pacotes de aplicacao (library/application/
# framework); pacotes de SO da imagem base ficam fora, pois sao controlados
# pela allowlist de imagem base, nao pela politica de licenca de dependencias.
conftest test sbom.cdx.json --policy policies/rego/license_policy.rego --namespace supply.license
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 6) Scan de vulnerabilidades CRITICAL/HIGH"
# --exit-code 0: aqui o scan e so informativo (lista achados no terminal).
# O gate que efetivamente bloqueia o pipeline fica no release.yml/verify.yml.
trivy image --timeout 15m -q --severity CRITICAL,HIGH --exit-code 0 --format table api-pagamentos:local | Select-Object -Last 15

Write-Host ""
Write-Host "== 7) Cenario adversarial local: Dockerfile e manifest inseguros DEVEM falhar"
# Prova negativa das policies: se este Dockerfile (base nao aprovada + root)
# passasse no gate, a policy estaria frouxa demais.
Set-Content -Path "$env:TEMP\Dockerfile.bad" -NoNewline -Value "FROM ubuntu:latest`nUSER root`n"
conftest test "$env:TEMP\Dockerfile.bad" --parser dockerfile --policy policies/rego/image_baseline.rego --namespace supply.image
if ($LASTEXITCODE -eq 0) {
    Write-Host "ERRO: Dockerfile inseguro deveria ser bloqueado"
    exit 1
}
Write-Host "   bloqueado (esperado)"
# Mesma ideia para o manifest: roda como root e usa tag mutavel (:latest) em
# vez de pin por digest - ambos devem ser rejeitados pelo gate de k8s.
(Get-Content k8s/deployment.yaml) `
    -replace 'runAsNonRoot: true', 'runAsNonRoot: false' `
    -replace '@sha256:[0-9a-f]*', ':latest' |
    Set-Content "$env:TEMP\deploy.bad.yaml"
conftest test "$env:TEMP\deploy.bad.yaml" --policy policies/rego/k8s_deployment.rego --namespace supply.k8s
if ($LASTEXITCODE -eq 0) {
    Write-Host "ERRO: manifest inseguro deveria ser bloqueado"
    exit 1
}
Write-Host "   bloqueado (esperado)"

Write-Host ""
Write-Host "Lab 08 OK - assinatura keyless, provenance SLSA L3 e gate no cluster exigem o repositorio no GitHub (ver README)."
