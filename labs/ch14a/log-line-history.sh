#!/usr/bin/env bash
# Chapter 14A, section 14A.12: git log -L follows a range of lines, or one function, back through
# history, across renames, and shows each commit's effect on just those lines.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a log-line-history
fx_scorekit || exit 1

snip 01-function-commits
run 'git log --oneline -s -L :token_f1:scorekit/metrics.py'

snip 02-compare
run 'git log --oneline --follow -- scorekit/metrics.py'

snip 03-one-line
run "git log --format='%h %an: %s' -L 2,2:scorekit/config.py"

snip 04-function-patch
run "git log --format='%h %an: %s' -L :normalize:scorekit/text.py -2"

snip 05-errors
run_rc 'git log --oneline -L 40,45:scorekit/config.py'
run_rc 'git log --oneline -L :no_such_function:scorekit/text.py'
run_rc 'git log --oneline -L 2,2:scorekit/config.py -- scorekit/config.py'
lab_end
