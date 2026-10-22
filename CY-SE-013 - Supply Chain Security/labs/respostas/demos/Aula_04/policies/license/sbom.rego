package main

import rego.v1

# Licencas que a organizacao nao aceita (IDs SPDX)
forbidden := {"GPL-3.0-only", "GPL-3.0-or-later", "AGPL-3.0-only", "AGPL-3.0-or-later"}

# Syft inclui entradas type="file" no CycloneDX; a politica olha apenas pacotes.
# Mesmo criterio usado pelo jq em run.sh/Makefile (PKG='.components[] | select(.type != "file")'),
# para que a contagem via jq e a avaliacao via Rego nunca divirjam.
packages contains c if {
    c := input.components[_]
    c.type != "file"
}

deny contains msg if {
    component := packages[_]
    lic := component.licenses[_].license.id
    forbidden[lic]
    not exempt_dotnet_os_license(component)
    msg := sprintf("Componente '%v' com licenca nao permitida: %v.", [component.name, lic])
}

# Excecao para aplicacoes .Net: a presenca de pacotes NuGet no SBOM indica que o
# GPL-3 encontrado e de utilitarios de SO (bash, coreutils, tar, ...) trazidos
# pela imagem base por mera agregacao, nao linkados/distribuidos junto do
# binario .Net - isso nao aciona as obrigacoes de copyleft da GPL-3 sobre a
# aplicacao. A excecao nao cobre pacotes NuGet: uma dependencia .Net GPL-3
# continua bloqueada normalmente.
is_dotnet_app if {
    some c in packages
    startswith(c.purl, "pkg:nuget/")
}

exempt_dotnet_os_license(component) if {
    is_dotnet_app
    not startswith(component.purl, "pkg:nuget/")
}

deny contains msg if {
    component := packages[_]
    missing_purl(component)
    msg := sprintf("Componente '%v' sem PURL.", [component.name])
}

# PURL ausente (chave nao definida/null) ou PURL declarado como string vazia
missing_purl(component) if {
    not component.purl
}

missing_purl(component) if {
    component.purl == ""
}

# Avisa (nao bloqueia) quando o pacote nao declara licenca alguma (ausente ou lista vazia)
warn contains msg if {
    component := packages[_]
    no_license(component)
    msg := sprintf("Componente '%v' nao declara licenca.", [component.name])
}

no_license(component) if {
    not component.licenses
}

no_license(component) if {
    component.licenses == []
}
