package supply.image

# Baseline de imagem: base aprovada, pinada por digest, sem root, sem tag latest

approved_bases := {"cgr.dev/chainguard/", "gcr.io/distroless/", "docker.io/library/node", "node"}

deny contains msg if {
    input[i].Cmd == "from"
    image := input[i].Value[0]
    not approved(image)
    msg := sprintf("linha %d: base '%v' fora da allowlist", [i, image])
}

deny contains msg if {
    input[i].Cmd == "from"
    image := input[i].Value[0]
    not contains(image, "@sha256:")
    msg := sprintf("linha %d: base '%v' deve ser pinada por digest", [i, image])
}

deny contains msg if {
    input[i].Cmd == "from"
    endswith(input[i].Value[0], ":latest")
    msg := sprintf("linha %d: tag latest proibida", [i])
}

deny contains msg if {
    input[i].Cmd == "user"
    input[i].Value[0] == "root"
    msg := sprintf("linha %d: USER root proibido", [i])
}

deny contains msg if {
    is_array(input)
    not has_user
    msg := "Dockerfile sem instrucao USER"
}

has_user if { input[_].Cmd == "user" }

approved(image) if {
    some base in approved_bases
    startswith(image, base)
}
