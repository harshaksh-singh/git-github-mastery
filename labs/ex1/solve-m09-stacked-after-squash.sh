#!/usr/bin/env bash
# Replay of Exercise 9.9 (Level 4, the rebase that replays somebody else's commits): diagnosis
# and repair as real transcripts for solutions/exercises-m06-m10.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m09-stacked-after-squash
exercise_load m09-stacked-after-squash

snip 01-state
run 'cd policy-engine'
run 'git status'

snip 02-todo
run 'cat .git/rebase-merge/done | grep -v "^#"'
run 'cat .git/rebase-merge/git-rebase-todo | grep -v "^#" | grep .'
run 'cat .git/rebase-merge/head-name'

snip 03-abort
run 'git rebase --abort'
run 'git status -sb'
run 'git log --graph --format="%h %an: %s" --all'

snip 04-why
run 'git log --format="%h %an: %s" main..feat/pii-redaction'
run 'git show --stat --format="%h %s (parents: %p)" main'
note 'Is the squash commit recognized as a copy of the three commits? Compare patch IDs.'
run 'git cherry -v main feat/pii-redaction'

snip 05-onto
note 'Replay only what is yours: everything after the last commit of the old parent branch.'
base=$(git log --format=%h -1 --author=Asha feat/pii-redaction)
run "git rebase --onto main $base feat/pii-redaction"
run 'git log --graph --format="%h %an: %s" --all'

snip 06-verify
run 'git range-diff ORIG_HEAD~2..ORIG_HEAD main..HEAD'
run 'git diff --stat main HEAD'

snip 07-check
run 'cd ..'
show_check
exercise_done
