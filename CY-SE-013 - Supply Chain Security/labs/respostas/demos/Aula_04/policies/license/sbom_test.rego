package main

import rego.v1

test_deny_forbidden_license if {
    deny["Componente 'libfoo' com licenca nao permitida: GPL-3.0-only."] with input as {
        "components": [{"type": "library", "name": "libfoo", "purl": "pkg:deb/debian/libfoo@1.0",
                        "licenses": [{"license": {"id": "GPL-3.0-only"}}]}],
    }
}

test_deny_missing_purl if {
    deny["Componente 'libbar' sem PURL."] with input as {
        "components": [{"type": "library", "name": "libbar", "licenses": [{"license": {"id": "MIT"}}]}],
    }
}

test_warn_missing_license if {
    warn["Componente 'libbaz' nao declara licenca."] with input as {
        "components": [{"type": "library", "name": "libbaz", "purl": "pkg:npm/libbaz@2.0"}],
    }
}

test_deny_empty_purl if {
    deny["Componente 'libqux' sem PURL."] with input as {
        "components": [{"type": "library", "name": "libqux", "purl": "",
                        "licenses": [{"license": {"id": "MIT"}}]}],
    }
}

test_warn_empty_license_array if {
    warn["Componente 'libquux' nao declara licenca."] with input as {
        "components": [{"type": "library", "name": "libquux", "purl": "pkg:npm/libquux@1.0", "licenses": []}],
    }
}

test_ignore_file_entries if {
    count(deny) == 0 with input as {
        "components": [{"type": "file", "name": "/etc/passwd"}],
    }
}

test_allow_clean_component if {
    count(deny) == 0 with input as {
        "components": [{"type": "library", "name": "express", "purl": "pkg:npm/express@4.19.2",
                        "licenses": [{"license": {"id": "MIT"}}]}],
    }
}

test_dotnet_app_exempts_os_gpl3 if {
    count(deny) == 0 with input as {
        "components": [
            {"type": "library", "name": "Newtonsoft.Json", "purl": "pkg:nuget/Newtonsoft.Json@13.0.3",
             "licenses": [{"license": {"id": "MIT"}}]},
            {"type": "library", "name": "bash", "purl": "pkg:deb/ubuntu/bash@5.2.21",
             "licenses": [{"license": {"id": "GPL-3.0-only"}}]},
        ],
    }
}

test_dotnet_app_still_denies_gpl3_nuget_package if {
    deny["Componente 'SomeCopyleftLib' com licenca nao permitida: GPL-3.0-only."] with input as {
        "components": [
            {"type": "library", "name": "Newtonsoft.Json", "purl": "pkg:nuget/Newtonsoft.Json@13.0.3",
             "licenses": [{"license": {"id": "MIT"}}]},
            {"type": "library", "name": "SomeCopyleftLib", "purl": "pkg:nuget/SomeCopyleftLib@1.0",
             "licenses": [{"license": {"id": "GPL-3.0-only"}}]},
        ],
    }
}

test_non_dotnet_app_still_denies_os_gpl3 if {
    deny["Componente 'bash' com licenca nao permitida: GPL-3.0-only."] with input as {
        "components": [{"type": "library", "name": "bash", "purl": "pkg:deb/ubuntu/bash@5.2.21",
                        "licenses": [{"license": {"id": "GPL-3.0-only"}}]}],
    }
}
