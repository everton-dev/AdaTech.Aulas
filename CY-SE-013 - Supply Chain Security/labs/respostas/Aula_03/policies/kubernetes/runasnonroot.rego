package main

# Versao standalone (Conftest), para checar manifests antes do apply, da
# mesma regra aplicada em runtime pelo Gatekeeper via
# templates/runasnonroot.yaml. O Gatekeeper recebe o Pod dentro de
# input.review.object; aqui o Conftest entrega o manifest direto em input.

exempt_images := {"gcr.io/google-containers/pause"}

deny contains msg if {
    input.kind == "Pod"
    container := input.spec.containers[_]
    not container.securityContext.runAsNonRoot
    not exempt(container.image)
    msg := sprintf("Container '%v' deve declarar runAsNonRoot: true.", [container.name])
}

exempt(image) if {
    some prefix in exempt_images
    startswith(image, prefix)
}
