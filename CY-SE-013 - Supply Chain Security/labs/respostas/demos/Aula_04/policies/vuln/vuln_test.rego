package main

import rego.v1

test_deny_high_severity if {
    deny["Vulnerabilidade CVE-2024-21907 (severidade HIGH) no componente 'Newtonsoft.Json' versao 12.0.1."] with input as {
        "components": [{"bom-ref": "comp-1", "name": "Newtonsoft.Json", "version": "12.0.1"}],
        "vulnerabilities": [{
            "id": "CVE-2024-21907",
            "ratings": [{"severity": "high"}],
            "affects": [{"ref": "comp-1"}],
        }],
    }
}

test_deny_critical_severity if {
    deny["Vulnerabilidade CVE-9999-00001 (severidade CRITICAL) no componente 'libexample' versao 1.0.0."] with input as {
        "components": [{"bom-ref": "comp-2", "name": "libexample", "version": "1.0.0"}],
        "vulnerabilities": [{
            "id": "CVE-9999-00001",
            "ratings": [{"severity": "critical"}],
            "affects": [{"ref": "comp-2"}],
        }],
    }
}

test_allow_low_and_medium_severity if {
    count(deny) == 0 with input as {
        "components": [{"bom-ref": "comp-3", "name": "libokay", "version": "2.0.0"}],
        "vulnerabilities": [
            {"id": "CVE-0001", "ratings": [{"severity": "low"}], "affects": [{"ref": "comp-3"}]},
            {"id": "CVE-0002", "ratings": [{"severity": "medium"}], "affects": [{"ref": "comp-3"}]},
        ],
    }
}

test_allow_empty_vulnerabilities_array if {
    count(deny) == 0 with input as {
        "components": [{"bom-ref": "comp-4", "name": "libclean", "version": "3.0.0"}],
        "vulnerabilities": [],
    }
}

test_allow_missing_vulnerabilities_key if {
    count(deny) == 0 with input as {
        "components": [{"bom-ref": "comp-5", "name": "libclean2", "version": "1.0.0"}],
    }
}

test_deny_unresolved_affected_ref if {
    deny["Vulnerabilidade CVE-8888-00002 (severidade HIGH) afeta o componente de referencia 'comp-missing' (nao encontrado em components)."] with input as {
        "components": [{"bom-ref": "comp-6", "name": "libother", "version": "1.0.0"}],
        "vulnerabilities": [{
            "id": "CVE-8888-00002",
            "ratings": [{"severity": "high"}],
            "affects": [{"ref": "comp-missing"}],
        }],
    }
}
