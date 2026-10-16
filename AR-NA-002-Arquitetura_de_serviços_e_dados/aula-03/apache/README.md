# Aula 03 - Primeiro desafio com Apache

## Etapa 1: página padrão

```powershell
docker pull httpd
docker run -d --name meu-apache -p 80:80 httpd
docker ps
```

Abra `http://localhost:80`. O Apache exibirá `It works!`.

## Etapa 2: alterar a página inicial

O script remove o container anterior e monta a pasta `site/` no diretório público do Apache:

```powershell
./run-apache.ps1
```

Abra `http://localhost:80` novamente. Alterações em `site/index.html` aparecem após atualizar o navegador.

Se a porta `80` estiver ocupada, use outra:

```powershell
./run-apache.ps1 -HostPort 8080
```

## Alterar um container que ja esta em execucao

Para copiar `site/index.html` para o container `meu-apache` sem recria-lo:

```powershell
./update-apache-html.ps1
```

Tambem e possivel informar outro container ou arquivo:

```powershell
./update-apache-html.ps1 -ContainerName outro-apache -HtmlPath ./site/index.html
```

O script salva a pagina anterior como `/usr/local/apache2/htdocs/index.html.backup` dentro do container.

## Comandos úteis

```powershell
docker logs meu-apache
docker stop meu-apache
docker start meu-apache
docker rm -f meu-apache
```