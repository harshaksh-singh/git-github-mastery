#!/usr/bin/env bash
# Final test, lab "fork" (spanlog): the model solution as real transcripts for
# answer-keys/final-test-answers.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin final solve-fork
final_load fork

snip 01-observe
run 'cd you'
run 'git status -sb'
run 'git remote -v'
run 'git log --oneline --graph --all'

snip 02-upstream
run 'git remote add upstream ../upstream.git'
run 'git fetch upstream'
run 'git log --oneline --graph --all'
run 'git log --oneline upstream/main..main'

snip 03-branch
note 'The two commits get a name first. Then the copy on top of the project is made.'
run 'git switch -c fix/utc-timestamps'
run 'git rebase upstream/main'
run 'git push -u origin fix/utc-timestamps'

snip 04-main
note 'main is not checked out, so the ref can be moved without touching any file.'
run 'git branch -f main upstream/main'
run 'git push --force-with-lease=main:origin/main origin main'

snip 05-verify
run 'git log --oneline --graph --all'
run 'git branch -vv'
run 'cd ..'
show_check
final_done
