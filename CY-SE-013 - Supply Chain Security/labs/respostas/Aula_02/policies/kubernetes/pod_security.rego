package main

deny contains msg if {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.runAsUser == 0
    msg := sprintf("Container '%v' nao pode rodar como UID 0.", [container.name])
}

deny contains msg if {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container '%v' sem limite de memoria.", [container.name])
}

# Variaveis sensiveis devem vir de secretKeyRef, nunca literais
sensitive_names := {"password", "secret", "token", "apikey", "api_key"}

deny contains msg if {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    env := container.env[_]
    is_sensitive(env.name)
    not env.valueFrom.secretKeyRef
    msg := sprintf("Variavel '%v' parece sensivel e deve vir de secretKeyRef.", [env.name])
}

is_sensitive(name) if {
    n := lower(name)
    some s in sensitive_names
    contains(n, s)
}
