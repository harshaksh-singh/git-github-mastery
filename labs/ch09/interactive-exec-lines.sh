#!/usr/bin/env bash
# Chapter 9, section 9.6: "exec" is an ordinary line of the todo list. --exec writes one after every
# commit; here the list is edited so that the check runs only once, at the end. The check then fails
# at the tip, which says that the branch is broken but not which commit broke it.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 interactive-exec-lines
fx_metrics_leftover

snip 01-exec-lines
run_todo '2d; 4d' 'git rebase -i --exec "sh scripts/check.sh" main'

snip 02-where
run 'git log --oneline --decorate -3'
run 'git status | head -8'

snip 03-abort
run 'git rebase --abort'
run 'git status --short --branch'
lab_end
