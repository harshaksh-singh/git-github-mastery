#!/usr/bin/env bash
# Replay of Exercise 10.9 (Level 4, a backport that stopped at its second commit): diagnosis and
# completion as real transcripts for solutions/exercises-m06-m10.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m10-backport-in-progress
exercise_load m10-backport-in-progress

snip 01-state
run 'cd vocab-service'
run 'git status'
run 'git log --oneline -3'

snip 02-sequencer
run 'git log -1 --format="%h %s" CHERRY_PICK_HEAD'
run 'cat .git/sequencer/todo'
run 'git log --format="%h %s" release/3.2..main'

snip 03-conflict
run 'git diff'
run 'git show :1:svc/limits.py'

snip 04-resolve
run "printf 'MAX_INPUT = 2048\n\ndef check(text):\n    if len(text) > MAX_INPUT:\n        raise ValueError(\"input too long\")\n' > svc/limits.py"
run 'git add svc/limits.py'
run 'git cherry-pick --continue'

snip 05-verify
run 'git status -sb'
run 'git log --format="%h %s%n   %b" -3'
run 'git cherry -v release/3.2 main'
run 'git diff --stat main release/3.2'
run 'cat svc/limits.py'

snip 06-check
run 'cd ..'
show_check
exercise_done
