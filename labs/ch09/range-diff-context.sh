#!/usr/bin/env bash
# Chapter 9, section 9.14: a limit of "git range-diff". A one-line commit whose context changed
# during the rebase is not recognised as the same commit: it is reported as removed (<) and added (>).
# A larger --creation-factor makes range-diff pair the two, and the inner diff then shows that only a
# context line differs.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 range-diff-context
fx_rerank_clean
tick; tick               # same clock position as rebase-basic, so the copies get the IDs shown in section 9.2
quiet 'git rebase main feat/rerank'

snip 01-unpaired
note 'The clean rebase of section 9.2. Nothing was edited, and yet:'
run 'git range-diff main ORIG_HEAD HEAD'

snip 02-paired
run 'git range-diff --creation-factor=90 main ORIG_HEAD HEAD'
lab_end
