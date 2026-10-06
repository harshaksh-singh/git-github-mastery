#!/usr/bin/env bash
# Chapter 9, section 9.14: the reviewer's side. A branch under review was rebased and force-pushed.
# After "git fetch", the previous tip is still in the reflog of the remote-tracking branch, so
# "git range-diff" can answer: did anything change besides the base?
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 range-diff-review
fx_shared_branch
quiet 'git rebase main'
quiet 'git push --force-with-lease --force-if-includes'
cd ../asha || exit 1
quiet 'git switch main'

snip 01-fetch
note 'In the reviewer clone. The author has rebased feat/ingest onto main and force-pushed it.'
run 'git fetch'
note 'The remote-tracking branch before and after that fetch:'
run 'git rev-parse "origin/feat/ingest@{1}" origin/feat/ingest'

snip 02-range-diff
run 'git range-diff origin/main "origin/feat/ingest@{1}" origin/feat/ingest'
lab_end
