package main

test_deny_root_user if {
    deny["Instrucao #1: USER 'root' proibido."] with input as [
        {"Cmd": "from", "Value": ["cgr.dev/chainguard/static:latest"]},
        {"Cmd": "user", "Value": ["root"]},
    ]
}

test_deny_unapproved_base if {
    deny["Instrucao #0: imagem base 'ubuntu:latest' nao aprovada."] with input as [
        {"Cmd": "from", "Value": ["ubuntu:latest"]},
        {"Cmd": "user", "Value": ["1001"]},
    ]
}

test_deny_missing_user if {
    deny["Dockerfile sem instrucao USER."] with input as [
        {"Cmd": "from", "Value": ["cgr.dev/chainguard/static:latest"]},
    ]
}

test_allow_valid_dockerfile if {
    count(deny) == 0 with input as [
        {"Cmd": "from", "Value": ["cgr.dev/chainguard/static:latest"]},
        {"Cmd": "user", "Value": ["1001"]},
    ]
}
