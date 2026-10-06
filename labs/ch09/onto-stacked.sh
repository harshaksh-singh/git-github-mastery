#!/usr/bin/env bash
# Chapter 9, section 9.5, --onto case 1: a branch stacked on another branch that was squash-merged.
# A plain "git rebase main" replays the parent branch's commits too; --onto replays only your own.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 onto-stacked
fx_ingest_squashed

snip 01-before
run 'git log --oneline --graph --decorate --all'

snip 02-which-commits
note 'What a plain "git rebase main" would replay:'
run 'git log --oneline main..feat/ingest-cleaner'
note 'What belongs to this branch alone:'
run 'git log --oneline feat/ingest-loader..feat/ingest-cleaner'

snip 03-plain-rebase-conflicts
run_rc 'git rebase main'
run 'git rebase --abort'

snip 04-onto
run 'git rebase --onto main feat/ingest-loader feat/ingest-cleaner'
run 'git log --oneline --graph --decorate --all'
lab_end
