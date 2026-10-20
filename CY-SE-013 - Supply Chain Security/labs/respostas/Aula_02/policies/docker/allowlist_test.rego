package docker.allowlist

# "with data.docker.approved_images as [...]" troca a allowlist so' para o
# teste, sem depender do arquivo data/approved_images.json do disco.

test_deny_imagem_fora_da_allowlist if {
    deny["FALHA: imagem base 'ubuntu' nao esta na allowlist."]
        with input as {"config": {"Image": "ubuntu:latest"}}
        with data.docker.approved_images as ["cgr.dev/chainguard/static"]
}

test_allow_imagem_na_allowlist if {
    count(deny) == 0
        with input as {"config": {"Image": "cgr.dev/chainguard/static:latest"}}
        with data.docker.approved_images as ["cgr.dev/chainguard/static"]
}
