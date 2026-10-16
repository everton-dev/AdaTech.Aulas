package supply.sbom

# Todo release precisa de SBOM CycloneDX valido com metadata e componentes com PURL

deny contains msg if {
    not input.bomFormat == "CycloneDX"
    msg := "SBOM deve estar no formato CycloneDX"
}

deny contains msg if {
    not input.metadata.component.name
    msg := "SBOM sem metadata.component.name (artefato principal nao identificado)"
}

deny contains msg if {
    not input.metadata.timestamp
    msg := "SBOM sem timestamp de geracao"
}

deny contains msg if {
    count(input.components) == 0
    msg := "SBOM sem componentes"
}

deny contains msg if {
    c := input.components[_]
    c.type == "library"
    not c.purl
    msg := sprintf("componente %v sem PURL", [c.name])
}
