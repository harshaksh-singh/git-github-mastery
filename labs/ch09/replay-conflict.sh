#!/usr/bin/env bash
# Chapter 9, section 9.20: "git replay" cannot stop for a conflict. In the repository of section 9.4
# it exits with status 1, prints nothing, and leaves the branch where it was.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 replay-conflict
fx_rerank_conflict
git switch -q main

snip 01-conflict
run_rc 'git replay --onto=main main..feat/rerank'
run 'git log --oneline --decorate -1 feat/rerank'
run 'git status --short --branch'
lab_end
