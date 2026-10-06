#!/usr/bin/env bash
# Replay of Exercise 1.9 (Level 4, "git log says there are no commits"): diagnosis and repair as
# real transcripts for solutions/exercises-m01-m05.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m01-unborn-main
exercise_load m01-unborn-main

snip 01-symptom
run 'cd chunk-index'
run_rc 'git log --oneline'
run 'git status'

snip 02-evidence
run 'cat .git/HEAD'
run 'git for-each-ref'
run 'git branch -vv'
run 'git log --oneline trunk'
run 'git fsck'

snip 03-repair
run 'git branch -m trunk main'
run 'git for-each-ref'
run 'git status'
run 'git log --oneline'

snip 04-check
run 'cd ..'
show_check
exercise_done
