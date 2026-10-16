package supply.pipeline

# Politica sobre o proprio workflow do GitHub Actions

deny contains msg if {
    step := input.jobs[_].steps[_]
    uses := step.uses
    not regex.match(`@[a-f0-9]{40}($|\s)`, uses)
    msg := sprintf("action '%v' deve ser fixada por SHA de commit, nao por tag", [uses])
}

deny contains msg if {
    not input.permissions
    msg := "workflow sem bloco 'permissions' (principio do menor privilegio)"
}

deny contains msg if {
    input.permissions == "write-all"
    msg := "permissions: write-all e proibido"
}
