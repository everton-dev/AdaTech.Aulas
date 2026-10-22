# syntax=docker/dockerfile:1.7
# Sem precedente .NET no repo: imagens tag-pinned (nao digest-pinned) porque o
# instrutor deve resolver/validar um digest atual antes de cada aula com:
#   docker inspect --format='{{index .RepoDigests 0}}' <imagem>
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY AdaSupplyDemo.csproj ./
RUN dotnet restore
COPY . .
RUN dotnet publish --output /app --configuration Release

FROM mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated10.0 AS runtime
WORKDIR /home/site/wwwroot
COPY --from=build /app .

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

# A imagem de runtime do Azure Functions e historicamente testada rodando como
# root. Se o host nao subir com este usuario, remova as duas linhas abaixo.
RUN groupadd --system appgroup && useradd --system --gid appgroup appuser \
    && chown -R appuser:appgroup /home/site/wwwroot
USER appuser
