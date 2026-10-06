#!/usr/bin/env bash
# Final test, lab "branching" (driftwatch): the model solution as real transcripts for
# answer-keys/final-test-answers.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin final solve-branching
final_load branching

snip 01-observe
run 'cd driftwatch'
run 'git status -sb'
run 'git log --oneline --graph --all --decorate'
run 'git reflog -5'

snip 02-name
run_rc 'git branch fix/window-size "HEAD@{1}"'
run 'git branch -vv'
run 'git branch --merged main'

snip 03-repair
run 'git branch -d fix'
run 'git switch -c fix/window-size "HEAD@{1}"'
run 'git log --oneline --graph --all --decorate'
run 'cd ..'
show_check
final_done
