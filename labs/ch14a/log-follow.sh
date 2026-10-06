#!/usr/bin/env bash
# Chapter 14A, section 14A.10: the history of one file across renames with --follow, and where
# --follow stops working.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a log-follow
fx_scorekit || exit 1

snip 01-without
run 'git log --oneline -- scorekit/metrics.py'

snip 02-follow
run 'git log --oneline --follow -- scorekit/metrics.py'

snip 03-names
run "git log --follow --diff-filter=AR --name-status --format='%h %s' -- scorekit/metrics.py"

snip 04-old-names
note 'Without --follow, the old names can be given as extra paths, if you know them:'
run 'git log --oneline -- scorekit/metrics.py scorekit/scorer.py scorer.py'

snip 05-one-path
run_rc 'git log --oneline --follow -- scorekit/metrics.py scorekit/text.py'
lab_end
