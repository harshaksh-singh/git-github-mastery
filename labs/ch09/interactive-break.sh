#!/usr/bin/env bash
# Chapter 9, section 9.6: "break" pauses the rebase without touching a commit, and
# "git rebase --edit-todo" changes the rest of the plan while paused.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 interactive-break
fx_metrics_messy

snip 01-break
run_todo_cmd '{ sed -n 1,3p "$f"; echo break; sed -n 4,6p "$f"; } > "$f.new" && mv "$f.new" "$f"' 'git rebase -i main'

snip 02-look-around
run 'git log --oneline --decorate -4'
run 'sh scripts/check.sh'

snip 03-edit-list
run_todo '1s/^pick/drop/' 'git rebase --edit-todo'

snip 04-continue
run 'git rebase --continue'
run 'git log --oneline --decorate'
run 'sh scripts/check.sh'
lab_end
