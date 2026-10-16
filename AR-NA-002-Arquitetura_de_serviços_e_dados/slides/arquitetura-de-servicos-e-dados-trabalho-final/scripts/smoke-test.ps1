param(
    [string]$BaseUrl = "http://localhost"
)

$ErrorActionPreference = "Stop"

$health = Invoke-RestMethod "$BaseUrl/health"
if (([string]$health).Trim() -ne "ok") {
    throw "Proxy indisponivel."
}

$created = Invoke-RestMethod "$BaseUrl/api/products" `
    -Method Post `
    -ContentType "application/json" `
    -Body '{"name":"Produto smoke test"}'

if (-not $created.id) {
    throw "A API nao retornou o ID do produto criado."
}

$updated = Invoke-RestMethod "$BaseUrl/api/products/$($created.id)" `
    -Method Put `
    -ContentType "application/json" `
    -Body '{"name":"Produto validado"}'

if ($updated.name -ne "Produto validado") {
    throw "A atualizacao do produto falhou."
}

Invoke-RestMethod "$BaseUrl/api/products/$($created.id)" -Method Delete

$page = Invoke-WebRequest -UseBasicParsing "$BaseUrl/"
if ($page.StatusCode -ne 200 -or $page.Content -notmatch "Stockroom") {
    throw "O frontend nao respondeu com o conteudo esperado."
}

Write-Host "Smoke test concluido: proxy, frontend e CRUD estao operacionais."