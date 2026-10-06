#!/usr/bin/env bash
# Chapter 9, section 9.5, --onto case 3: remove a range of commits from the middle of a branch.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 onto-cut
fx_rerank_experiments

snip 01-before
run 'git log --oneline --decorate'

snip 02-onto
note 'Keep everything up to feat/rerank~4, drop ~3 and ~2, replay ~1 and the tip.'
run 'git rebase --onto feat/rerank~4 feat/rerank~2 feat/rerank'
run 'git log --oneline --decorate'

snip 03-check
run 'git diff --stat ORIG_HEAD HEAD'
lab_end
