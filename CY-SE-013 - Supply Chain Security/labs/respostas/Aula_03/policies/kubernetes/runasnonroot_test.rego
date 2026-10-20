package main

test_deny_pod_sem_runasnonroot if {
    deny["Container 'web' deve declarar runAsNonRoot: true."] with input as {
        "kind": "Pod",
        "spec": {"containers": [{"name": "web", "image": "nginx:1.27"}]},
    }
}

test_allow_pod_com_runasnonroot if {
    count(deny) == 0 with input as {
        "kind": "Pod",
        "spec": {"containers": [{
            "name": "web",
            "image": "nginxinc/nginx-unprivileged:1.27",
            "securityContext": {"runAsNonRoot": true, "runAsUser": 101},
        }]},
    }
}

test_allow_imagem_isenta if {
    count(deny) == 0 with input as {
        "kind": "Pod",
        "spec": {"containers": [{
            "name": "pause",
            "image": "gcr.io/google-containers/pause:3.9",
        }]},
    }
}
