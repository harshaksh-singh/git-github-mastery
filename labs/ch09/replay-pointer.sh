#!/usr/bin/env bash
# Chapter 9, section 9.20: a first look at the experimental "git replay" (Chapter 14D covers it).
# It rebases a branch that is not checked out, without touching the working tree or the index.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 replay-pointer
fx_rerank_clean

snip 01-replay
run 'git status --short --branch'
run_rc 'git replay --onto=main main..feat/rerank'
run 'git log --oneline --graph --decorate --all'
run 'git reflog show feat/rerank -2'
lab_end
