#!/usr/bin/env bash
# Chapter 14A, section 14A.20: a bisection by hand on regression 1. v0.1.0 scored the smoke set
# correctly, main does not. The first commit Git offers cannot be tested at all and is skipped.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a bisect-manual
fx_scorekit || exit 1

snip 01-start
run 'git rev-list --count v0.1.0..main'
run 'git bisect start'
run 'git bisect bad main'
run 'git bisect good v0.1.0'

snip 02-status
run 'git status'

snip 03-untestable
run 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1'
run 'git bisect skip'

snip 04-bad
run 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1'
run 'git bisect bad'

snip 05-good
run 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1'
run 'git bisect good'

snip 06-narrowing
run 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1'
run 'git bisect bad'
run 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1'
run 'git bisect good'

snip 07-found
run 'python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1'
run 'git bisect bad'

snip 08-state
run 'git for-each-ref --format="%(objectname:short) %(refname)" refs/bisect'
run 'ls .git | grep BISECT'
run 'cat .git/BISECT_START .git/BISECT_TERMS'
run 'git rev-parse --abbrev-ref HEAD'

snip 09-log
run 'git bisect log'

snip 10-reset
run 'git bisect reset'
run 'git status --short --branch'
run 'git for-each-ref refs/bisect | wc -l'
lab_end
