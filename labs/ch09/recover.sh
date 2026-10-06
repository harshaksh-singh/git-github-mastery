#!/usr/bin/env bash
# Chapter 9, section 9.16: undo a rebase. First with ORIG_HEAD right away, then through the reflog of
# the branch after ORIG_HEAD has been overwritten by a later command.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 recover
fx_rerank_experiments

snip 01-bad-rebase
run 'git log --oneline --decorate'
note 'The plan was to drop the two experiment commits. The wrong lines were deleted from the todo list.'
run_todo '4,5d' 'git rebase -i main'
run 'git log --oneline --decorate'

snip 02-orig-head
run 'git rev-parse --short ORIG_HEAD'
run 'git reset --hard ORIG_HEAD'
run 'git log --oneline --decorate'

snip 03-orig-head-overwritten
run_todo '4,5d' 'git rebase -i main' > /dev/null 2>&1   # hidden repeat of the bad rebase
note 'The same bad rebase again. This time you do not notice, and remove one more commit with a reset:'
run 'git reset --hard HEAD~1'
run 'git log --oneline --decorate'
run 'git rev-parse --short ORIG_HEAD'

snip 04-reflog
run 'git reflog show feat/rerank'

snip 05-rescue
run 'git branch rescue/rerank feat/rerank@{2}'
run 'git log --oneline rescue/rerank'
run 'git reset --hard rescue/rerank'
run 'git log --oneline --decorate'

snip 06-head-reflog
run 'git reflog -8'
lab_end
