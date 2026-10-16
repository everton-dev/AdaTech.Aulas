package supply.k8s

# Deployment seguro: nao-root, sem privilegio, imagem por digest, limites e sem secret literal

containers contains c if {
    input.kind == "Deployment"
    c := input.spec.template.spec.containers[_]
}

deny contains msg if {
    c := containers[_]
    not non_root(c)
    msg := sprintf("container %v deve ter runAsNonRoot: true", [c.name])
}

non_root(c) if { c.securityContext.runAsNonRoot == true }

deny contains msg if {
    c := containers[_]
    c.securityContext.privileged == true
    msg := sprintf("container %v nao pode ser privileged", [c.name])
}

deny contains msg if {
    c := containers[_]
    not contains(c.image, "@sha256:")
    msg := sprintf("container %v deve referenciar imagem por digest", [c.name])
}

deny contains msg if {
    c := containers[_]
    not c.resources.limits.memory
    msg := sprintf("container %v sem limite de memoria", [c.name])
}

sensitive := {"password", "secret", "token", "apikey", "api_key"}

deny contains msg if {
    c := containers[_]
    env := c.env[_]
    some s in sensitive
    contains(lower(env.name), s)
    not env.valueFrom.secretKeyRef
    msg := sprintf("variavel %v deve vir de secretKeyRef", [env.name])
}
