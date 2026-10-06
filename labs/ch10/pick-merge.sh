#!/usr/bin/env bash
# Chapter 10, section 10.4: cherry-picking a merge commit needs -m to say which parent is the base.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 pick-merge
fx_gateway_merge

snip 01-before
run 'git log --oneline --graph --decorate --all'

snip 02-refused
run_rc 'git cherry-pick main'

snip 03-mainline
run 'git cherry-pick -m 1 -x main'
run 'git show --stat --format="%h %s%n%b" HEAD'
run 'git log --oneline --graph --decorate release/1.4'
lab_end
