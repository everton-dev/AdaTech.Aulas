package main

import rego.v1

# Severidades que bloqueiam o gate
severe := {"critical", "high"}

# CycloneDX do Trivy inclui "vulnerabilities[]"; o do Syft nao faz scan de
# vulnerabilidade e nao inclui esse array. Por isso esta politica deve ser
# executada contra o CycloneDX do Trivy (sbom-trivy.cdx.json), nao o do Syft.
components_by_ref[ref] := c if {
    c := input.components[_]
    ref := c["bom-ref"]
}

severities_of(vuln) := {sev |
    rating := vuln.ratings[_]
    sev := lower(rating.severity)
}

deny contains msg if {
    vuln := input.vulnerabilities[_]
    sev := severities_of(vuln)[_]
    severe[sev]
    affected := vuln.affects[_]
    comp := components_by_ref[affected.ref]
    msg := sprintf("Vulnerabilidade %v (severidade %v) no componente '%v' versao %v.", [vuln.id, upper(sev), comp.name, comp.version])
}

deny contains msg if {
    vuln := input.vulnerabilities[_]
    sev := severities_of(vuln)[_]
    severe[sev]
    affected := vuln.affects[_]
    not components_by_ref[affected.ref]
    msg := sprintf("Vulnerabilidade %v (severidade %v) afeta o componente de referencia '%v' (nao encontrado em components).", [vuln.id, upper(sev), affected.ref])
}
