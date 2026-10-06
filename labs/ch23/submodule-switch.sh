#!/usr/bin/env bash
# Switching between a commit that has the submodule and one that does not: the directory that stays
# behind, and --recurse-submodules. Chapter 23, section 23.9.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 submodule-switch
fx_docqa_submodule
cd doc-qa

snip 01-stray-directory
run 'git log --oneline'
run 'git switch --detach HEAD~1'
run 'git status'
run 'ls -A vendor/textsplit'

snip 02-back
run 'git switch main'
run 'git status --short'

snip 03-recurse
run 'git switch --recurse-submodules --detach HEAD~1'
run 'git status --short'
run 'ls vendor 2>&1'
run 'git switch --recurse-submodules main'
run 'git submodule status'
lab_end
