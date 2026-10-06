#!/usr/bin/env bash
# Chapter 9, section 9.11: the two other ways out of a stopped rebase, --skip and --quit
# (--abort is shown in rebase-internals, --continue in rebase-conflict).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 conflict-exits
fx_rerank_conflict
quiet 'git rebase main'

snip 01-skip
run 'git rebase --skip'
run 'git log --oneline --decorate main..HEAD'
run 'cat app/retriever.py'

snip 02-quit
quiet 'git reset --hard ORIG_HEAD'
quiet 'git rebase main'
run 'git rebase --quit'
run 'git status'
run 'git log --oneline --graph --decorate --all'

snip 03-after-quit
run_rc 'git switch feat/rerank'
run 'git reset --hard'
run 'git switch feat/rerank'
lab_end
