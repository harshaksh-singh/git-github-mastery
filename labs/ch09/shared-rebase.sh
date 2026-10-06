#!/usr/bin/env bash
# Chapter 9, section 9.15: what a teammate experiences when a shared branch is rebased and force-pushed.
# A bare repository plays the server; "you" and "asha" are two clones. Asha merges the rewritten branch
# into her copy of the old one and ends up with every shared commit twice.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 shared-rebase
fx_shared_branch

snip 01-you-rebase
run 'git log --oneline --graph --decorate --all'
run 'git rebase main'

snip 02-you-push
run_rc 'git push'
run 'git push --force-with-lease --force-if-includes'

snip 03-asha-before
run 'cd ../asha'
run 'git log --oneline --graph --decorate --all'

snip 04-asha-fetch
run 'git fetch'
run 'git status'

snip 05-asha-merges
run 'git pull --no-rebase'
run 'git log --oneline --graph --decorate'

snip 06-duplicates
run 'git log --oneline --left-right --cherry-mark ORIG_HEAD...origin/feat/ingest'
run 'git diff --stat ORIG_HEAD HEAD'

snip 07-repair
run 'git reset --hard ORIG_HEAD'
run 'git merge-base --fork-point origin/feat/ingest feat/ingest'
run 'git pull --rebase'
run 'git log --oneline --graph --decorate'
lab_end
