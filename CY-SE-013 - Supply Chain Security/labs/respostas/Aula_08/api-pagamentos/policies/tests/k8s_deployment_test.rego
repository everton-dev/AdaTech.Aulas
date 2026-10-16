package supply.k8s

base := {"name": "api", "image": "ghcr.io/empresa/api-pagamentos@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "securityContext": {"runAsNonRoot": true}, "resources": {"limits": {"memory": "256Mi"}},
    "env": [{"name": "DB_PASSWORD", "valueFrom": {"secretKeyRef": {"name": "db", "key": "pwd"}}}]}

deploy(c) := {"kind": "Deployment", "spec": {"template": {"spec": {"containers": [c]}}}}

test_allow_good if { count(deny) == 0 with input as deploy(base) }

test_deny_root if {
    # object.union e recursivo; usamos object.remove para tirar o securityContext
    deny["container api deve ter runAsNonRoot: true"] with input as deploy(object.remove(base, ["securityContext"]))
}

test_deny_privileged if {
    deny["container api nao pode ser privileged"] with input as deploy(object.union(base, {"securityContext": {"runAsNonRoot": true, "privileged": true}}))
}

test_deny_tag_image if {
    deny["container api deve referenciar imagem por digest"] with input as deploy(object.union(base, {"image": "ghcr.io/empresa/api-pagamentos:v1"}))
}

test_deny_literal_secret if {
    deny["variavel API_TOKEN deve vir de secretKeyRef"] with input as deploy(object.union(base, {"env": [{"name": "API_TOKEN", "value": "x"}]}))
}
