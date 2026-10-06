#!/usr/bin/env bash
# Chapter 9, section 9.6: interactive rebase, one todo command at a time, on a messy branch:
# the todo list itself, then reword, fixup, reordering, squash and drop.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 interactive-basics
fx_metrics_messy

snip 01-messy
run 'git log --oneline --decorate'

snip 02-list
note 'Using "cat" as the editor prints the todo list exactly as Git wrote it and saves it unchanged.'
run 'GIT_SEQUENCE_EDITOR=cat git rebase -i main'

snip 03-reword
LAB_MSG='Add token-level F1 metric' run_todo '5s/^pick/reword/' 'git rebase -i main'
run 'git log --oneline'

snip 04-fixup
run_todo '2s/^pick/fixup/' 'git rebase -i main'
run 'git log --oneline'

snip 05-reorder
run_todo_cmd '{ sed -n 1,2p "$f"; sed -n 5p "$f"; sed -n 3,4p "$f"; } > "$f.new" && mv "$f.new" "$f"' 'git rebase -i main'
run 'git log --oneline'

snip 06-squash
LAB_MSG='Test exact_match, including surrounding whitespace' run_todo '3s/^pick/squash/' 'git rebase -i main'
run 'git log --oneline'

snip 07-drop
run_todo '3s/^pick/drop/' 'git rebase -i main'
run 'git log --oneline --decorate'

snip 08-result
run 'git show --stat --format="%h %s" HEAD~2 HEAD~1 HEAD'
lab_end
