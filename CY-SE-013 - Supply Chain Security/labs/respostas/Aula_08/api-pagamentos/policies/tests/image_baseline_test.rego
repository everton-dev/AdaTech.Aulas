package supply.image

good := [
    {"Cmd": "from", "Value": ["cgr.dev/chainguard/node:20@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"]},
    {"Cmd": "user", "Value": ["65532"]},
]

test_allow_good_dockerfile if { count(deny) == 0 with input as good }

test_deny_unpinned_latest if {
    r := deny with input as [{"Cmd": "from", "Value": ["ubuntu:latest"]}, {"Cmd": "user", "Value": ["1001"]}]
    r["linha 0: base 'ubuntu:latest' fora da allowlist"]
    r["linha 0: base 'ubuntu:latest' deve ser pinada por digest"]
    r["linha 0: tag latest proibida"]
}

test_deny_root if {
    deny["linha 1: USER root proibido"] with input as [good[0], {"Cmd": "user", "Value": ["root"]}]
}

test_deny_missing_user if {
    deny["Dockerfile sem instrucao USER"] with input as [good[0]]
}
