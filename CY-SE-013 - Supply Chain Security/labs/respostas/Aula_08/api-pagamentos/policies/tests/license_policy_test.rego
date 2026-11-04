package supply.license

test_deny_gpl3 if {
    deny["componente foo viola licenca proibida GPL-3.0-only"] with input as {
        "components": [{"type": "library", "name": "foo", "licenses": [{"license": {"id": "GPL-3.0-only"}}]}],
    }
}

test_allow_mit if {
    count(deny) == 0 with input as {
        "components": [{"type": "library", "name": "foo", "licenses": [{"license": {"id": "MIT"}}]}],
    }
}

test_ignore_file_entries if {
    count(deny) == 0 with input as {
        "components": [{"type": "file", "name": "/bin/sh", "licenses": [{"license": {"id": "GPL-3.0-only"}}]}],
    }
}

test_ignore_os_deb_package if {
    count(deny) == 0 with input as {
        "components": [{
            "type": "library",
            "name": "bash",
            "purl": "pkg:deb/debian/bash@5.2.15-2?arch=amd64&distro=debian-12.13",
            "licenses": [{"license": {"id": "GPL-3.0-only"}}],
        }],
    }
}

test_deny_app_package_even_when_typed_library if {
    deny["componente left-pad viola licenca proibida GPL-3.0-only"] with input as {
        "components": [{
            "type": "library",
            "name": "left-pad",
            "purl": "pkg:npm/left-pad@1.0.0",
            "licenses": [{"license": {"id": "GPL-3.0-only"}}],
        }],
    }
}
