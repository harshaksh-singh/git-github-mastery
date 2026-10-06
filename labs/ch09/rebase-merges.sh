#!/usr/bin/env bash
# Chapter 9, section 9.10: a branch that contains a merge commit. A plain rebase flattens it;
# --rebase-merges recreates the merge. The removed --preserve-merges is shown failing.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 rebase-merges
fx_ingest_with_merge

snip 01-before
run 'git log --oneline --graph --decorate --all'

snip 02-flattened
run 'git rebase main'
run 'git log --oneline --graph --decorate feat/ingest'

snip 03-undo
run 'git reset --hard ORIG_HEAD'

snip 04-rebase-merges
run_todo '' 'git rebase -i --rebase-merges main'

snip 05-after
run 'git log --oneline --graph --decorate --all'

snip 06-preserve-merges
run_rc 'git rebase --preserve-merges main'
lab_end
