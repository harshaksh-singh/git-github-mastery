#!/usr/bin/env bash
# Replay of Exercise 8.9 (Level 4, one public bad commit and one private mixed commit): diagnosis
# and repair as real transcripts for solutions/exercises-m06-m10.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m08-undo-mix
exercise_load m08-undo-mix

snip 01-observe
run 'cd you'
run 'git status -sb'
run 'git log --oneline --stat'

snip 02-private
note 'Which commits are private? Only what the server does not have.'
run 'git fetch'
run 'git log --oneline origin/main..main'
run 'git log --oneline -S"PASS_MARK = 0.5" -- grader/threshold.py'

snip 03-split
note 'The mixed commit is private: take it back, keep its changes in the working tree.'
run 'git reset HEAD~1'
run 'git status --short'
run 'git add configs/grader.yaml'
run 'git commit -m "Raise the grader timeout to 60 seconds"'
run 'git status --short'

snip 04-revert
bad=$(git log --format=%h -1 --grep='Lower the pass mark')
note 'The bad commit is public: a new commit that applies its inverse.'
run "git revert --no-edit $bad"
run 'git status --short'
run 'git log --oneline'
run 'cat grader/threshold.py'

snip 05-push
run 'git push'
run 'git status -sb'
run 'git diff --stat'

snip 06-check
run 'cd ..'
show_check
exercise_done
