#!/usr/bin/env bash
# file/directory: one branch adds a file named docs, the other adds a directory named docs.
# Chapter 8, section 8.11.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 conflict-file-directory

quiet 'ek_base'
quiet 'git switch -c feature/docs-directory'
as asha
quiet 'mkdir docs && printf "# Judge calibration guide\n" > docs/calibration.md && ek_commit "Add a docs directory"'
as you
quiet 'git switch main'
quiet 'printf "See the wiki.\n" > docs && ek_commit "Add a docs pointer file"'

snip 01-merge
run_rc 'git merge feature/docs-directory'
run 'git status --short'
run 'git ls-files -s docs docs~HEAD'
quiet 'git merge --abort'

lab_end
