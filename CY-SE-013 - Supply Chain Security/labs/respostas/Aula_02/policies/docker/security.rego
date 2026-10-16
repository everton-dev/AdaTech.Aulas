package main

# Allowlist de imagens-base aprovadas
approved_base := {
    "cgr.dev/chainguard/static",
    "gcr.io/distroless/base",
    "registry.k8s.io/pause",
}

deny contains msg if {
    input[i].Cmd == "from"
    image := input[i].Value[0]
    not is_approved(image)
    msg := sprintf("Instrucao #%d: imagem base '%v' nao aprovada.", [i, image])
}

deny contains msg if {
    input[i].Cmd == "user"
    input[i].Value[0] == "root"
    msg := sprintf("Instrucao #%d: USER 'root' proibido.", [i])
}

deny contains msg if {
    is_array(input)  # Dockerfile (lista de instrucoes); evita disparar em manifests K8s
    not has_user
    msg := "Dockerfile sem instrucao USER."
}

has_user if {
    input[_].Cmd == "user"
}

is_approved(image) if {
    some base in approved_base
    startswith(image, base)
    # exige delimitador apos o prefixo (":" de tag, "@" de digest, ou fim da
    # string) para "static-backdoor" nao ser aprovado por comecar com "static"
    rest := substring(image, count(base), -1)
    rest == ""
}

is_approved(image) if {
    some base in approved_base
    startswith(image, base)
    rest := substring(image, count(base), 1)
    rest in {":", "@"}
}
