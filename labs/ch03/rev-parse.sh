#!/usr/bin/env bash
# Chapter 3, section 3.6: git rev-parse, the command that turns names into object IDs
# and answers questions about the repository itself.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/common/inference-service.sh" || exit 1
lab_begin ch03 rev-parse
build_inference_service

snip 01-revisions
run 'git log --graph --oneline'
run 'git rev-parse HEAD'
run 'git rev-parse --short HEAD'
note '~2 follows first parents twice. ^2 is the second parent of a merge. ^1 is the first.'
run 'git rev-parse HEAD~2 HEAD^2 HEAD^1'
note 'From a commit to its tree, to a subtree, to a blob:'
run 'git rev-parse "HEAD^{tree}" HEAD:src HEAD:src/server.py'
note 'A tag object, and the commit it peels to:'
run 'git rev-parse v1.0.0 "v1.0.0^{commit}"'

snip 02-names
run 'git rev-parse --abbrev-ref HEAD'
run 'git rev-parse --symbolic-full-name HEAD'
run 'git rev-parse --symbolic-full-name v1.0.0 feature/batching'
note 'The previous value of a branch comes from its reflog:'
run 'git rev-parse "main@{1}"'
note 'A leading colon reads the index, not a commit:'
run 'git rev-parse :config.toml'

snip 03-repository
run 'git rev-parse --git-dir --show-toplevel'
run 'cd src/handlers'
run 'git rev-parse --git-dir'
run 'git rev-parse --show-prefix --show-cdup'
run 'git rev-parse --is-inside-work-tree --is-bare-repository'
run 'git rev-parse --show-object-format --show-ref-format'
run 'git rev-parse --git-path hooks/pre-commit'
run 'cd ../..'

snip 04-errors
note 'Without --verify, rev-parse prints what it cannot resolve on standard output:'
run 'id=$(git rev-parse no-such-branch 2>/dev/null); echo "status=$? captured=[$id]"'
note 'With --verify it prints one object ID or nothing, and --quiet drops the message:'
run 'id=$(git rev-parse --verify --quiet no-such-branch); echo "status=$? captured=[$id]"'
run_rc 'git rev-parse --verify no-such-branch'
run_rc 'git rev-parse --verify --quiet "v1.0.0^{commit}"'
note '--short implies --verify, so it accepts exactly one revision:'
run_rc 'git rev-parse --short HEAD~2 HEAD^2'
note 'A merge with two parents has no third parent:'
run_rc 'git rev-parse --verify "HEAD^3"'

lab_end
