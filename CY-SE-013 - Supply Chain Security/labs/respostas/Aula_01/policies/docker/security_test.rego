package docker.security

test_deny_root_user if {
    deny["FALHA: Imagem nao pode executar como root."] with input as {"config": {"User": "root"}}
}

test_allow_non_root_user if {
    count(deny) == 0 with input as {"config": {"User": "1001"}}
}

test_deny_missing_user if {
    deny["FALHA: Defina um usuario nao-privilegiado na imagem."] with input as {"config": {}}
}
