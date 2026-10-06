#!/usr/bin/env bash
# Lab 12.6 replay: two commits were made on main instead of feature/pdf-tables and are not
# pushed. Copy them to the right branch with a cherry-pick of the range origin/main..main,
# then move main back with "reset --keep". Failure: main is reset first. Recovery: the same
# range, taken from the reflog of main.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 lab-12-6-wrong-branch
fx_12_6

snip 01-symptom
run 'cd ingest'
run 'git status -sb'
run 'git log --oneline --graph --all'
run 'git log --oneline origin/main..main'

snip 02-copy
run 'git switch feature/pdf-tables'
run 'git cherry-pick origin/main..main'
run 'git log --oneline -3'

snip 03-move-main-back
run 'git switch main'
run 'git reset --keep origin/main'
run 'git status -sb'

snip 04-verification
run 'git log --oneline --graph --all'
run 'git cherry -v feature/pdf-tables ORIG_HEAD'
run 'git diff --stat ORIG_HEAD feature/pdf-tables'

snip 05-failure
run 'cd ../ingest-incident'
run 'git status -sb'
note 'Tidy main first, copy later:'
run 'git reset --hard origin/main'
run 'git log --oneline --graph --all'

snip 06-recovery
run 'git reflog show main -3'
run "git log --oneline origin/main..'main@{1}'"
run 'git switch feature/pdf-tables'
run "git cherry-pick origin/main..'main@{1}'"

snip 07-after
run 'git log --oneline --graph --all'
run 'ls'

lab_end
