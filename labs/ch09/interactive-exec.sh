#!/usr/bin/env bash
# Chapter 9, section 9.6: "exec" runs a command after each replayed commit. A failing command stops the
# rebase at the commit that broke the check, so it can be amended before continuing.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 interactive-exec
fx_metrics_leftover

snip 01-setup
run 'git log --oneline --decorate'
run 'cat scripts/check.sh'

snip 02-exec-stops
run_rc 'git rebase --exec "sh scripts/check.sh" main'

snip 03-where
run 'git log --oneline --decorate -2'
run 'cat .git/rebase-merge/git-rebase-todo'

snip 04-fix-and-continue
note 'In an editor: delete the DEBUG line from eval/f1.py. Then:'
grep -v 'DEBUG' eval/f1.py > eval/f1.py.new && mv eval/f1.py.new eval/f1.py
run 'git diff --stat'
run 'git commit -a --amend --no-edit'
run 'git rebase --continue'
lab_end
