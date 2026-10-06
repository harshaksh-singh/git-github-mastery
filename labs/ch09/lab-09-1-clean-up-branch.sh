#!/usr/bin/env bash
# Lab 9.1 replay: clean up a messy branch with one interactive rebase, verify that the content is
# what you intended, then lose a commit on purpose by deleting a todo line and get it back.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 lab-09-1-clean-up-branch
fx_metrics_messy

snip 01-start
run 'git log --oneline --decorate'

snip 02-rebase
printf 'Test exact_match, including surrounding whitespace\n----\nAdd token-level F1 metric\n' > "$LAB_DIR/messages"
LAB_MSG_QUEUE="$LAB_DIR/messages" run_todo_cmd '{ sed -n 1p "$f"; sed -n 2p "$f" | sed "s/^pick/fixup/"; sed -n 3p "$f" | sed "s/^pick/reword/"; sed -n 6p "$f" | sed "s/^pick/fixup/"; sed -n 4p "$f" | sed "s/^pick/drop/"; sed -n 5p "$f" | sed "s/^pick/reword/"; } > "$f.new" && mv "$f.new" "$f"' 'git rebase -i main'

snip 03-result
run 'git log --oneline --decorate'

snip 03a-reflog
run 'git reflog -8'

snip 04-verify
run 'git diff ORIG_HEAD HEAD'
run 'sh scripts/check.sh'

snip 05-failure
note 'A second interactive rebase. The line of the F1 commit is deleted by accident.'
run_todo '3d' 'git rebase -i main'
run 'git log --oneline --decorate'

snip 06-diagnose
run 'git diff --stat ORIG_HEAD HEAD'
run 'git range-diff main ORIG_HEAD HEAD'

snip 07-recovery
run 'git reset --hard ORIG_HEAD'
run 'git log --oneline --decorate'

snip 08-prevention
run 'git config set rebase.missingCommitsCheck error'
run_todo '3d' 'git rebase -i main'
run 'git rebase --abort'

snip 09-verification
run 'git status --short --branch'
run 'git log --oneline main..HEAD'
run 'sh scripts/check.sh'
lab_end
