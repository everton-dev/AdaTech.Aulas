package main

# Formato Conftest: cada instrucao do Dockerfile vira {"Cmd": "...", "Value": [...]}
deny contains msg if {
    input[i].Cmd == "user"
    val := input[i].Value[0]
    val == "root"
    msg := sprintf("Instrucao #%d: USER 'root' nao e permitido.", [i])
}

deny contains msg if {
    not has_user
    msg := "Dockerfile nao define instrucao USER. Adicione um usuario nao-privilegiado."
}

has_user if {
    input[_].Cmd == "user"
}
