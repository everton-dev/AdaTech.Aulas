# Aula 07 — Integridade e Procedência de Artefatos

## Objetivo
Assinar uma imagem, anexar SBOM/provenance e verificar a identidade e a integridade do artefato.

## Pré-requisitos
- **Docker** em execução (o registry local é um container: `docker run -d -p 5000:5000 registry:2`).
- **Cosign 3.x**, **Syft** e **jq** (ver [INSTALACAO.md](INSTALACAO.md)):

| Sistema | Cosign |
|---|---|
| Windows | `winget install sigstore.cosign` ou baixe `cosign-windows-amd64.exe` em <https://github.com/sigstore/cosign/releases/latest> e renomeie para `cosign.exe` |
| macOS | `brew install cosign` |
| Linux | `curl -LO https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64 && sudo install cosign-linux-amd64 /usr/local/bin/cosign` |

```bash
cosign version && syft version && docker ps
```

> **Cosign 3.x com chave local:** use `--tlog-upload=false --use-signing-config=false` ao assinar/atestar e `--insecure-ignore-tlog` ao verificar (evita publicar o laboratório no Rekor público). Em produção, use keyless (OIDC) sem essas flags. Para a chave de teste, exporte `COSIGN_PASSWORD` para não ser perguntado.
- Para o passo opcional (policy-controller), **kind + kubectl + helm**.

## Passos
1. Inicie um registry local e construa uma imagem de teste; publique-a com tag versionada.
2. Gere um par de chaves de laboratório com `cosign generate-key-pair`.
3. Assine a imagem por digest e verifique com `cosign verify --key cosign.pub`.
4. Gere SBOM CycloneDX com Syft e anexe-o como atestação Cosign.
5. Anexe uma provenance de laboratório; identifique claramente que é demonstrativa, não provenance de builder confiável.
6. Verifique as atestações e confira sujeito, digest, predicate e identidade.
7. Opcional: rode `test-k8s-policy.ps1`/`.sh`, que instala o policy-controller em um cluster kind e observa a rejeição de imagem não assinada.

## Verificação de sucesso
A verificação da assinatura e das atestações passa para o digest esperado; uma imagem adulterada ou sem assinatura não deve ser aceita pelo gate.

## Entregáveis
Imagem identificada por digest, chaves de teste, SBOM, provenance demonstrativa e saídas de verificação.

## Resposta e teste automatizado
`respostas/Aula_07/` — `bash respostas/Aula_07/run.sh` sobe o registry, assina o **digest**, anexa SBOM (`cyclonedx`) e provenance (`slsaprovenance1`), verifica as duas atestações e prova que uma imagem adulterada **falha** no `cosign verify`. Inclui `ClusterImagePolicy` keyless e workflow `verify-deploy.yml`. Limpeza: `run.sh --cleanup`.

`test-k8s-policy.ps1`/`.sh` sobe um cluster kind, instala o policy-controller via Helm, aplica o `ClusterImagePolicy` keyless (`k8s/cluster-image-policy-keyless.yaml`) e demonstra a rejeição de uma imagem não assinada pelo admission webhook — o caminho de aceitação exige assinatura keyless real via GitHub Actions (ver `verify-deploy.yml`) e não é simulável localmente. Limpeza: `test-k8s-policy.ps1 -Cleanup` / `test-k8s-policy.sh --cleanup`.