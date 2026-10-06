#!/usr/bin/env bash
# Chapter 9, sections 9.2 to 9.4: a plain rebase with no conflict. Shows the graph before and after,
# the new commit IDs, what is and is not preserved in the commit objects, and the reflog trail.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 rebase-basic
fx_rerank_clean

snip 01-before
run 'git log --oneline --graph --decorate --all'

snip 02-rebase
run 'git switch feat/rerank'
run 'git rebase main'

snip 03-after
run 'git log --oneline --graph --decorate --all'
run 'git log --oneline main..ORIG_HEAD'

snip 04-objects
note 'The first commit of the branch, before the rebase (reachable through ORIG_HEAD) ...'
run 'git cat-file -p ORIG_HEAD~2'
note '... and its replacement after the rebase.'
run 'git cat-file -p HEAD~2'

snip 05-patch-id
run 'git show ORIG_HEAD~2 | git patch-id --stable'
run 'git show HEAD~2 | git patch-id --stable'

snip 06-reflog
run 'git reflog -6'
run 'git reflog show feat/rerank'

snip 07-nothing-to-do
run 'git rebase main'
run 'git switch main'
run 'git rebase feat/rerank'
run 'git log --oneline --graph --decorate --all'
lab_end
