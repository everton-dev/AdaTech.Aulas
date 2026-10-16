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
