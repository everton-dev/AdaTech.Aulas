package main

good_deployment := {
    "kind": "Deployment",
    "spec": {"template": {"spec": {"containers": [{
        "name": "api",
        "securityContext": {"runAsUser": 1001},
        "resources": {"limits": {"memory": "256Mi"}},
        "env": [{"name": "DB_PASSWORD", "valueFrom": {"secretKeyRef": {"name": "db", "key": "pwd"}}}],
    }]}}},
}

test_allow_good_deployment if {
    count(deny) == 0 with input as good_deployment
}

test_deny_uid_zero if {
    deny["Container 'api' nao pode rodar como UID 0."] with input as {
        "kind": "Deployment",
        "spec": {"template": {"spec": {"containers": [{
            "name": "api",
            "securityContext": {"runAsUser": 0},
            "resources": {"limits": {"memory": "256Mi"}},
        }]}}},
    }
}

test_deny_missing_memory_limit if {
    deny["Container 'api' sem limite de memoria."] with input as {
        "kind": "Deployment",
        "spec": {"template": {"spec": {"containers": [{
            "name": "api",
            "securityContext": {"runAsUser": 1001},
            "resources": {"limits": {"cpu": "500m"}},
        }]}}},
    }
}

test_deny_literal_secret if {
    deny["Variavel 'API_TOKEN' parece sensivel e deve vir de secretKeyRef."] with input as {
        "kind": "Deployment",
        "spec": {"template": {"spec": {"containers": [{
            "name": "api",
            "securityContext": {"runAsUser": 1001},
            "resources": {"limits": {"memory": "256Mi"}},
            "env": [{"name": "API_TOKEN", "value": "abc123"}],
        }]}}},
    }
}
