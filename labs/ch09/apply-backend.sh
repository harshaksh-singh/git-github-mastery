#!/usr/bin/env bash
# Chapter 9, sections 9.4 and 9.24: the older "apply" backend, which older tutorials and old answers
# describe. Same conflict as in rebase-internals, different messages, a different state directory and
# less informative conflict labels.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 apply-backend
fx_rerank_conflict

snip 01-apply-stops
run_rc 'git rebase --apply main'

snip 02-state
run 'ls .git | grep rebase'
run 'ls .git/rebase-apply | head -5'
run 'git status | head -2'
run 'head -5 app/retriever.py'

snip 03-abort
run 'git rebase --abort'
run 'git status --short --branch'
lab_end
