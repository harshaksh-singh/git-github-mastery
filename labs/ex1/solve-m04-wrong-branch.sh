#!/usr/bin/env bash
# Replay of Exercise 4.9 (Level 4, three commits on the wrong branch): diagnosis and repair as
# real transcripts for solutions/exercises-m01-m05.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m04-wrong-branch
exercise_load m04-wrong-branch

snip 01-symptom
run 'cd you'
run_rc 'git push'
run 'git status -sb'

snip 02-evidence
run 'git branch -vv'
run 'git log --graph --oneline --all'
run 'git branch --merged origin/main'
run 'git branch --no-merged origin/main'

snip 03-repair
note 'A new name for the commit you are on: no commit changes, the edit stays in the working tree.'
run 'git switch -c feature/rate-limit'
note 'main is no longer the current branch, so its ref can be moved without touching any file.'
run 'git branch -f main origin/main'
run 'git branch -d feature/old-cache'
run_rc 'git branch -d spike/token-bucket'

snip 04-push
run 'git push -u origin feature/rate-limit'
run 'git branch -vv'
run 'git status --short'
run 'git log --graph --oneline --all'

snip 05-check
run 'cd ..'
show_check
exercise_done
