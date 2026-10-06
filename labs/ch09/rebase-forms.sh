#!/usr/bin/env bash
# Chapter 9, section 9.5: the two-argument form "git rebase <upstream> <branch>" switches to <branch>
# first, and "git rebase" without arguments needs a configured upstream branch.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 rebase-forms
fx_rerank_clean

snip 01-two-arguments
run 'git status --short --branch'
run 'git rebase main feat/rerank'
run 'git status --short --branch'
run 'git reflog -5'

snip 02-no-upstream
run_rc 'git rebase'
lab_end
