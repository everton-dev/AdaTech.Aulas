package supply.license

denied_licenses := {"GPL-3.0-only", "GPL-3.0-or-later", "AGPL-3.0-only", "AGPL-3.0-or-later", "SSPL-1.0"}

# Pacotes de SO da imagem base (ex.: libc, bash) ficam fora de escopo: sao
# governados pela allowlist de base aprovada em image_baseline.rego, nao por
# licenca de dependencia de aplicacao.
package_types := {"library", "application", "framework"}

deny contains msg if {
    component := input.components[_]
    package_types[component.type]
    license := component.licenses[_].license.id
    denied_licenses[license]
    msg := sprintf("componente %v viola licenca proibida %v", [component.name, license])
}
