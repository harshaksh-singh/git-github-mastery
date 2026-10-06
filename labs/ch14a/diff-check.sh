#!/usr/bin/env bash
# Chapter 14A, section 14A.6: git diff --check finds whitespace errors and leftover conflict markers
# and reports them through its exit status.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a diff-check
fx_scorekit || exit 1

printf 'SMOKE_LIMIT = 10  \n' >> scorekit/config.py
printf '<<<<<<< HEAD\nrouge_l is experimental.\n' >> docs/metrics.md

snip 01-check
note 'A line with two trailing spaces in config.py, a forgotten conflict marker in docs/metrics.md.'
run_rc 'git diff --check'

snip 02-staged
run 'git add -A'
run_rc 'git diff --check'
run_rc 'git diff --cached --check'

snip 03-range
note 'The same test for commits that already exist: did the last release introduce any?'
run_rc 'git diff --check v0.1.0 v0.2.0'
lab_end
