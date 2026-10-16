package docker.security

# Nega imagens que rodam como root
deny contains msg if {
    input.config.User == "root"
    msg := "FALHA: Imagem nao pode executar como root."
}

# Nega imagens sem usuario definido
deny contains msg if {
    not input.config.User
    msg := "FALHA: Defina um usuario nao-privilegiado na imagem."
}
