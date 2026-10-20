package docker.allowlist

# Exemplo de "Allowlist em data" (ver slide PADRÕES).
# Em policies/docker/security.rego a allowlist (approved_base) fica escrita
# dentro da política. Aqui ela vem de data/approved_images.json, carregado
# à parte com --data: para liberar/remover uma imagem, o time de segurança
# edita só o JSON, sem tocar, revisar ou reaprovar o código Rego.

# Nega qualquer imagem cuja base não esteja em data.docker.approved_images
deny contains msg if {
    image := input.config.Image
    base := split(image, ":")[0] # "cgr.dev/chainguard/static:latest" -> "cgr.dev/chainguard/static"
    not base in data.docker.approved_images
    msg := sprintf("FALHA: imagem base '%v' nao esta na allowlist.", [base])
}
