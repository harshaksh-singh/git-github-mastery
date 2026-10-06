#!/usr/bin/env bash
# Chapter 9, sections 9.11 and 9.21: two ways to lose a commit while resolving a rebase conflict.
# Trap 1: "git restore --ours" keeps the upstream version, so your commit becomes empty and is dropped.
# Trap 2: "git commit --amend" folds the resolution into the previous commit.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 conflict-traps
fx_rerank_conflict
quiet 'git rebase main'

snip 01-ours-trap
note 'The rebase is stopped at "Fetch 20 candidates for the reranker". You want your version, so you type:'
run 'git restore --ours app/retriever.py'
run 'git add app/retriever.py'
run 'git status --short'
run 'git rebase --continue'

snip 02-ours-result
run 'git log --oneline --decorate main..HEAD'
run 'git range-diff main ORIG_HEAD HEAD'

snip 03-amend-trap
quiet 'git reset --hard ORIG_HEAD'
quiet 'git rebase main'
note 'Stopped at the same commit. This time the resolution is right, but the next command is not:'
run 'git restore --theirs app/retriever.py'
run 'git add app/retriever.py'
run 'git commit --amend --no-edit'
run 'git rebase --continue'

snip 04-amend-result
run 'git log --oneline --decorate main..HEAD'
run 'git show --stat --format="%h %s" HEAD~1'
lab_end
