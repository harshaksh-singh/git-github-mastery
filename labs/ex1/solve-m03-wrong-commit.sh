#!/usr/bin/env bash
# Replay of Exercise 3.9 (Level 4, a commit made on the meeting-room laptop): diagnosis and repair
# as real transcripts for solutions/exercises-m01-m05.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m03-wrong-commit
exercise_load m03-wrong-commit
as ravi          # in the lab shell the repository's own configuration supplies this identity

snip 01-observe
run 'cd scorer-service'
run 'git log --oneline'
run 'git show --stat --format=fuller HEAD'

snip 02-private
note 'Is the commit private? No remote, no upstream: nothing has left this repository.'
run 'git remote -v'
run 'git branch -vv'
run 'git var GIT_AUTHOR_IDENT'

snip 03-repair
run 'git rm --cached debug.log'
run 'git status --short'
MSG='Add retry budget to the scorer

A batch is retried until the budget of the run is used up, so one slow model cannot hold the whole evaluation.

Reviewed-by: Asha Rao <asha@example.com>'
run_msg "$MSG" "git commit --amend --author='Ravi Menon <ravi@example.com>'"

snip 04-verify
run 'git show --stat --format=fuller HEAD'
run 'git status --short'
run 'git log --oneline'

snip 05-old-commit
run 'git reflog -2'
run "git show -s --format='%h %an <%ae> %s' 'HEAD@{1}'"

snip 06-check
run 'cd ..'
show_check
exercise_done
