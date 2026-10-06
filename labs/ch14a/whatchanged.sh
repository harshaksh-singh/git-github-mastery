#!/usr/bin/env bash
# Chapter 14A, section 14A.24: git whatchanged is deprecated. Git 2.55 refuses to run it without an
# explicit flag and names the replacement.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a whatchanged
fx_scorekit || exit 1

snip 01-refuses
run_rc 'git whatchanged -2'

snip 02-replacement
run 'git log --raw --no-merges --oneline -2'
run 'git whatchanged --i-still-use-this --oneline -2'

snip 03-last-modified
note 'A newer plumbing command answers "which commit last touched each path". It is marked experimental.'
run 'git last-modified -r -- scorekit'
lab_end
