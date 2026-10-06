#!/usr/bin/env bash
# Chapter 9, section 9.11: looking around while a rebase is stopped at a conflict: the commit being
# replayed (--show-current-patch), the bookkeeping files that say what has been rewritten so far, and
# the two messages you get when you try to move on too early.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 conflict-inspect
fx_rerank_conflict
tick                      # same clock position as rebase-internals, so the replayed commit gets the same ID
quiet 'git rebase main'

snip 01-show-current-patch
run 'git rebase --show-current-patch'

snip 02-bookkeeping
run 'cat .git/rebase-merge/stopped-sha'
run 'cat .git/rebase-merge/rewritten-list'
run 'cat .git/rebase-merge/message'

snip 03-continue-too-early
run_rc 'git rebase --continue'

snip 04-second-rebase
run_rc 'git rebase main'

snip 05-abort
run 'git rebase --abort'
run_rc 'git rebase --continue'
lab_end
