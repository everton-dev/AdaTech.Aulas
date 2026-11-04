package supply.license

denied_licenses := {"GPL-3.0-only", "GPL-3.0-or-later", "AGPL-3.0-only", "AGPL-3.0-or-later", "SSPL-1.0"}

package_types := {"library", "application", "framework"}

# Pacotes de SO da imagem base (ex.: libc, bash) ficam fora de escopo: sao
# governados pela allowlist de base aprovada em image_baseline.rego, nao por
# licenca de dependencia de aplicacao. O syft marca esses pacotes .deb/.rpm/.apk
# com type "library" no CycloneDX (igual a uma dependencia de app), entao
# `package_types` sozinho nao os separa — o purl e que distingue a origem.
os_purl_prefixes := {"pkg:deb/", "pkg:rpm/", "pkg:apk/"}

is_os_package(component) if {
    prefix := os_purl_prefixes[_]
    startswith(component.purl, prefix)
}

deny contains msg if {
    component := input.components[_]
    package_types[component.type]
    not is_os_package(component)
    license := component.licenses[_].license.id
    denied_licenses[license]
    msg := sprintf("componente %v viola licenca proibida %v", [component.name, license])
}
