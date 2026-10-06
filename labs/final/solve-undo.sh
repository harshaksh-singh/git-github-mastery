#!/usr/bin/env bash
# Final test, lab "undo" (routeplan): the model diagnosis and repair as real transcripts for
# answer-keys/final-test-answers.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin final solve-undo
final_load undo

snip 01-observe
run 'cd you'
run 'git status -sb'
run 'git reflog -3'
run 'git fetch'
run 'git status -sb'
run 'git log --oneline --graph --all'

snip 02-difference
note 'The published commit against the amended one: this is what has to reach the server.'
run 'git diff origin/main~1 main'
note 'The shortcut that would lose work: the amended tree against the server tip.'
run 'git diff main origin/main -- weights.yaml'

snip 03-repair
run 'git branch rescue/amended'
run 'git reset --keep origin/main'
run 'git diff origin/main~1 rescue/amended | git apply'
run 'git diff'
run 'git commit -q -a -m "Correct the name of the toll weight"'
run 'git push'

snip 04-verify
run 'git log --oneline --graph --all'
run 'cat weights.yaml'
run 'git branch -D rescue/amended'
run 'cd ..'
show_check
final_done
