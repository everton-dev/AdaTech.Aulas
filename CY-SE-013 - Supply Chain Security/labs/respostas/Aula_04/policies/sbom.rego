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
    msg := sprintf("Componente '%v' com licenca nao permitida: %v.", [component.name, lic])
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
