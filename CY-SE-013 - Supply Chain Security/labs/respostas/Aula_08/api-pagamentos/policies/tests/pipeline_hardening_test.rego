package supply.pipeline

test_deny_tag_action if {
    deny["action 'actions/checkout@v4' deve ser fixada por SHA de commit, nao por tag"] with input as {
        "permissions": {"contents": "read"},
        "jobs": {"build": {"steps": [{"uses": "actions/checkout@v4"}]}},
    }
}

test_allow_sha_action if {
    count(deny) == 0 with input as {
        "permissions": {"contents": "read"},
        "jobs": {"build": {"steps": [{"uses": "actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11"}]}},
    }
}

test_deny_no_permissions if {
    deny["workflow sem bloco 'permissions' (principio do menor privilegio)"] with input as {"jobs": {}}
}
