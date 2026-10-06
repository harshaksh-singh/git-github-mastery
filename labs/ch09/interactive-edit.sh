#!/usr/bin/env bash
# Chapter 9, section 9.6: "edit" stops after applying a commit. Here the stop is used to split one
# commit that mixes two concerns into two commits.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 interactive-edit
fx_metrics_mixed

snip 01-before
run 'git log --oneline --decorate'
run 'git show --stat --format="%h %s" HEAD~1'

snip 02-edit-stops
run_todo '2s/^pick/edit/' 'git rebase -i main'

snip 03-split
run 'git reset HEAD^'
run 'git status --short'
run 'git add eval/f1.py'
run 'git commit -m "Add token-level F1 metric"'
run 'git commit -a -m "Raise max_tokens to 1024 for long answers"'

snip 04-continue
run 'git rebase --continue'
run 'git log --oneline --decorate'

snip 05-orig-head-moved
note 'ORIG_HEAD no longer names the tip from before the rebase: "git reset" overwrote it.'
run 'git rev-parse --short ORIG_HEAD'
run 'git diff --stat ORIG_HEAD HEAD'
note 'The reflog of the branch still has the old tip. The two trees are identical, so this prints nothing:'
run 'git diff --stat feat/metrics@{1} feat/metrics'
run 'git reflog show feat/metrics -2'
lab_end
