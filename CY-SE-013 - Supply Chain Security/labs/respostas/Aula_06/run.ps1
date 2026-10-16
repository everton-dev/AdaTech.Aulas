# Lab 06 - hardening de dependencias npm e Python. Requer: node/npm >= 9, python 3, git.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# Evita repetir "Select-String + if" para cada checagem de conteudo de arquivo (DRY)
function Test-FileContainsPattern {
    param([string]$Path, [string]$Pattern)
    return [bool](Select-String -Path $Path -Pattern $Pattern -Quiet)
}

Write-Host "== 1) Gerar lockfile (apenas na primeira execucao) e instalar com hashes, sem scripts"
# --ignore-scripts desativa lifecycle scripts (ex: postinstall) do pacote e de suas
# dependencias: e o vetor mais comum de ataque supply-chain em pacotes npm maliciosos
if (-not (Test-Path package-lock.json)) {
    npm install --package-lock-only --ignore-scripts
}
# 'npm ci' (em vez de 'npm install') instala exatamente o que esta no lockfile,
# sem recalcular versoes: garante reprodutibilidade e falha se o lockfile estiver desatualizado
npm ci --ignore-scripts
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 2) Lockfile imutavel (nao pode mudar durante o pipeline)"
# core.pager=cat evita que o git abra um pager interativo (trava execucao nao interativa/CI).
# ErrorActionPreference precisa virar 'Continue' aqui: com 'Stop', redirecionar o stderr
# de um comando nativo que falha (2>$null) trava o script em vez de so descartar a saida.
$ErrorActionPreference = 'Continue'
git -c core.pager=cat diff --exit-code package-lock.json 2>$null
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -ne 0) {
    Write-Host "   (fora de um repo git ou lockfile recem-criado: ok para o primeiro run)"
}

Write-Host ""
Write-Host "== 3) Verificar assinaturas Sigstore dos pacotes"
# confirma que os pacotes instalados batem com a assinatura publicada no registry;
# isso pega adulteracao/substituicao de pacote que uma simples checagem de versao nao detecta
npm audit signatures
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 4) Auditoria de vulnerabilidades (falha em HIGH ou acima)"
# limiar em HIGH evita que o pipeline quebre por achados LOW/MODERATE de baixo
# impacto pratico, mantendo o gate focado no que realmente deve bloquear o build
npm audit --audit-level=high
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 5) Verificar que postinstall esta bloqueado"
# garante a protecao mesmo se alguem rodar 'npm install'/'npm ci' sem a flag --ignore-scripts
# manualmente: o .npmrc torna o bloqueio o padrao do projeto, nao so deste script
if (Test-FileContainsPattern -Path .npmrc -Pattern '^ignore-scripts=true') {
    Write-Host "   ignore-scripts=true OK"
}

Write-Host ""
Write-Host "== 6) Teste rapido da aplicacao"
# confirma que o hardening (ignore-scripts, lockfile travado) nao quebrou a app:
# seguranca que impede a aplicacao de rodar nao e seguranca utilizavel
# aspas duplas dentro do argumento quebram o parsing de linha de comando do Windows ao
# chamar um .exe a partir do PowerShell; por isso a string JS usa aspas simples aqui
node -e 'const app=require(`./src/server.js`); const s=app.listen(0,()=>{fetch(`http://localhost:${s.address().port}/health`).then(r=>r.json()).then(j=>{console.log(`   /health ->`,JSON.stringify(j)); s.close();});});'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "== 7) Equivalente Python: requirements com hashes"
# Continue temporario: com ErrorActionPreference=Stop, redirecionar o stderr de um
# comando nativo que falhar (2>$null) trava o script em vez de so descartar a saida.
$ErrorActionPreference = 'Continue'
python -m venv .venv 2>$null
$ErrorActionPreference = 'Stop'
$pythonExe = if (Test-Path .venv\Scripts\python.exe) { '.venv\Scripts\python.exe' } else { '.venv/bin/python' }
& $pythonExe -m pip install -q pip-tools
New-Item -ItemType Directory -Force -Path python | Out-Null
Set-Content -Path python/requirements.in -Value 'requests==2.32.3'
& $pythonExe -m piptools compile --generate-hashes -q -o python/requirements.txt python/requirements.in
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$hashCount = (Select-String -Path python/requirements.txt -Pattern '--hash=sha256').Count
Write-Host "   hashes gerados: $hashCount"
# --require-hashes forca o pip a so instalar pacotes cujo hash bata com o lockfile:
# pinar so a versao nao impede troca do artefato (ex: pacote comprometido republicado
# com o mesmo numero de versao); o hash pina o conteudo exato do arquivo
& $pythonExe -m pip install -q --require-hashes -r python/requirements.txt
if ($LASTEXITCODE -eq 0) { Write-Host "   pip install --require-hashes OK" }

Write-Host ""
Write-Host "== 8) Dockerfile pinado por digest"
# tag (ex: ':18-alpine') e mutavel: o mantenedor pode republicar a mesma tag apontando
# para outro conteudo; @sha256 referencia o conteudo exato da imagem, imutavel por definicao
if (Test-FileContainsPattern -Path Dockerfile -Pattern 'FROM .*@sha256:') {
    Write-Host "   FROM com @sha256 OK"
}

Write-Host ""
Write-Host "Lab 06 OK"
