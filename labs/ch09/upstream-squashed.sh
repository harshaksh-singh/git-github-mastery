#!/usr/bin/env bash
# Chapter 9, section 9.12: the first two commits of your branch reached main as one squashed commit.
# No patch ID matches, so they are replayed, turn out to change nothing, and are dropped as empty.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 upstream-squashed
fx_ingest_partly_upstream squashed

snip 01-before
run 'git log --oneline --graph --decorate --all'
run 'git cherry -v main feat/ingest'

snip 02-rebase
run 'git rebase main'
run 'git log --oneline --graph --decorate --all'

snip 03-interactive-stops
quiet 'git reset --hard ORIG_HEAD'
note 'With -i the default is --empty=stop: the rebase pauses at each commit that became empty.'
run_rc 'git rebase -i main'
run 'git rebase --abort'
lab_end
