#!/usr/bin/env bash
# Chapter 14A, section 14A.3: summary formats of git diff and the --diff-filter option, between the
# two releases of scorekit.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a diff-summaries
fx_scorekit || exit 1

snip 01-stat
run 'git diff --stat v0.1.0 v0.2.0'
run 'git diff --shortstat v0.1.0 v0.2.0'

snip 02-names
run 'git diff --name-only v0.1.0 v0.2.0'
run 'git diff --name-status v0.1.0 main'

snip 03-numstat
run 'git diff --numstat v0.1.0 main'
run 'git diff --dirstat v0.1.0 main'

snip 04-filter
run 'git diff --name-status --diff-filter=A v0.1.0 main'
run 'git diff --name-status --diff-filter=D v0.1.0 main'
note 'Lowercase letters exclude: everything except additions and deletions.'
run 'git diff --name-status --diff-filter=ad v0.1.0 main'

snip 05-pathspec
run "git diff --stat v0.1.0 main -- '*.py' ':(exclude)scorekit/runner.py'"
lab_end
