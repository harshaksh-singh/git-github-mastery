#!/usr/bin/env bash
# Chapter 9, section 9.12: a commit of your branch is already on main as a cherry-pick (same patch,
# different ID). Rebase detects it by patch ID and leaves it out; --reapply-cherry-picks disables that.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 upstream-picked
fx_ingest_partly_upstream picked

snip 01-before
run 'git log --oneline --graph --decorate --all'

snip 02-predict
run 'git cherry -v main feat/ingest'
run 'git log --oneline --left-right --cherry-mark main...feat/ingest'

snip 03-rebase
run 'git rebase main'
run 'git log --oneline --graph --decorate --all'

snip 04-reapply
quiet 'git reset --hard ORIG_HEAD'
run 'git rebase --reapply-cherry-picks main'
run 'git log --oneline --decorate main..HEAD'
lab_end
