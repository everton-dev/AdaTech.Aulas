package supply.sbom

good := {
    "bomFormat": "CycloneDX", "specVersion": "1.5",
    "metadata": {"timestamp": "2026-11-03T10:00:00Z", "component": {"name": "api-pagamentos", "version": "1.0.0"}},
    "components": [{"type": "library", "name": "express", "version": "4.22.3", "purl": "pkg:npm/express@4.22.3"}],
}

test_allow_good_sbom if { count(deny) == 0 with input as good }

test_deny_wrong_format if {
    deny["SBOM deve estar no formato CycloneDX"] with input as object.union(good, {"bomFormat": "SPDX"})
}

test_deny_missing_metadata if {
    deny["SBOM sem metadata.component.name (artefato principal nao identificado)"] with input as object.remove(good, ["metadata"])
}

test_deny_missing_purl if {
    deny["componente express sem PURL"] with input as object.union(good, {"components": [{"type": "library", "name": "express"}]})
}

test_deny_empty if {
    deny["SBOM sem componentes"] with input as object.union(good, {"components": []})
}
