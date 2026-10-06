#!/usr/bin/env bash
# Chapter 9, section 9.6: what the editor shows when "squash" melds two commits. "cat" stands in
# for the message editor, so the proposed message is printed exactly as Git wrote it and is saved
# unchanged.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 squash-message
fx_metrics_clean

snip 01-squash-buffer
export GIT_EDITOR=cat
run_todo '2s/^pick/squash/' 'git rebase -i main'
export GIT_EDITOR=true

snip 02-result
run 'git log --oneline --decorate'
run 'git log -1 --format=%B HEAD~1'
run 'git show --stat --format="%h %s" HEAD~1'
lab_end
