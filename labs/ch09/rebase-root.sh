#!/usr/bin/env bash
# Chapter 9, section 9.5: --root makes the root commit itself part of the range, so even the first
# commit can be reworded. Every commit of the branch gets a new ID.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 rebase-root
fx_rerank_clean
git branch -q -D feat/rerank

snip 01-before
run 'git log --oneline --decorate'

snip 02-root
LAB_MSG='Add retriever and default model configuration' run_todo '1s/^pick/reword/' 'git rebase -i --root'

snip 03-after
run 'git log --oneline --decorate'
run 'git log --oneline ORIG_HEAD'
run_rc 'git merge-base HEAD ORIG_HEAD'
lab_end
