# Aula 02 - Wiki em containers

A mesma wiki estatica em `html/` pode ser servida por Nginx ou Apache.

## Publicar e executar com Nginx

```powershell
docker login
./nginx/publish-and-run.ps1 SEU_USUARIO_DOCKERHUB 80
```

## Publicar e executar com Apache

```powershell
docker login
./apache/publish-and-run.ps1 SEU_USUARIO_DOCKERHUB 80
```

Cada execucao incrementa automaticamente a versao registrada no `version.txt`, publica a imagem com uma tag como `v1`, `v2` ou `v3` e tambem atualiza a tag `latest`. O argumento opcional e a porta do host.

Como apenas um container pode usar a porta `80` por vez, o script para automaticamente o outro container desta wiki antes de iniciar. Containers de outros projetos nunca sao parados automaticamente.

```powershell
docker stop curriculo-wiki-nginx
./apache/publish-and-run.ps1 SEU_USUARIO_DOCKERHUB 80
```

Para manter os dois ativos, use portas diferentes, por exemplo `80` para Nginx e `8080` para Apache.