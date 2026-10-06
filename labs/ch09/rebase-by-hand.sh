#!/usr/bin/env bash
# Chapter 9, section 9.2: a rebase done by hand with the three operations that the manual names
# (detach HEAD at the new base, cherry-pick the range, move the branch), then compared with the
# result of "git rebase". Same trees, different commit IDs.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 rebase-by-hand
fx_rerank_clean

snip 01-detach-and-replay
run 'git switch --detach main'
run 'git cherry-pick main..feat/rerank'

snip 02-before-the-branch-moves
run 'git log --oneline --graph --decorate --all'

snip 03-move-the-branch
run 'git switch -C feat/rerank'
run 'git log --oneline --graph --decorate --all'

snip 04-compare-with-rebase
note 'Keep the hand-made result under a tag, put the branch back, and let "git rebase" do the job.'
run 'git tag by-hand'
run 'git reset --hard "feat/rerank@{1}"'
run 'git rebase main'
run 'git log --format="%h tree %t  %s" main..by-hand'
run 'git log --format="%h tree %t  %s" main..feat/rerank'
lab_end
