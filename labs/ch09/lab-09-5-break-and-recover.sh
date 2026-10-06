#!/usr/bin/env bash
# Lab 9.5 replay: wreck a branch with a careless interactive rebase, recover it with ORIG_HEAD, wreck
# it again, discover that ORIG_HEAD has moved, and recover it through the reflog of the branch.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 lab-09-5-break-and-recover
fx_rerank_clean
git switch -q feat/rerank

snip 01-start
run 'git log --oneline --graph --decorate --all'
run 'git rev-parse HEAD'

snip 02-break
LAB_MSG='wip' run_todo '1s/^pick/drop/; 3s/^pick/squash/' 'git rebase -i main'
run 'git log --oneline --decorate main..HEAD'
run 'ls app'

snip 03-orig-head
run 'git rev-parse ORIG_HEAD'
run 'git reset --hard ORIG_HEAD'
run 'git log --oneline --decorate main~2..HEAD'

snip 04-failure
LAB_MSG='wip' run_todo '1s/^pick/drop/; 3s/^pick/squash/' 'git rebase -i main' > /dev/null 2>&1   # hidden repeat
note 'The same careless rebase has been run again. Then you tidy up "one more thing":'
run 'git reset --hard HEAD~1'
note 'Now you notice that the branch is ruined and reach for the usual remedy:'
run 'git reset --hard ORIG_HEAD'
run 'git log --oneline --decorate main..HEAD'

snip 05-reflog
run 'git reflog show feat/rerank'

snip 06-recovery
run 'git branch rescue/rerank feat/rerank@{3}'
run 'git log --oneline rescue/rerank -3'
run 'git diff --stat rescue/rerank bd62876'
run 'git reset --hard rescue/rerank'

snip 07-verification
run 'git rev-parse HEAD'
run 'git log --oneline --graph --decorate --all'
run 'git branch -d rescue/rerank'
lab_end
