#!/usr/bin/env bash
# Lab 11.7 replay: the history of one function and of one line with git log -L, across a rename.
# The failure scenario takes a line number from an editor that shows uncommitted edits.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a lab-11-7-line-history
fx_scorekit || exit 1

snip 01-function-list
run "git log -s --format='%h %ad %<(10)%an %s' --date=short -L :token_f1:scorekit/metrics.py"

snip 02-newest
run "git log --format='%h %an: %s' -L :token_f1:scorekit/metrics.py -1"

snip 03-file-names
note 'The same log, reduced to the commit lines and the file names in each patch:'
run "git log --format='%h %an: %s' -L :token_f1:scorekit/metrics.py | grep -E '^[0-9a-f]{7} |^diff --git'"

snip 04-one-line
run 'grep -n "overlap = " scorekit/metrics.py'
run "git log -s --format='%h %ad %an: %s' --date=short -L 11,11:scorekit/metrics.py"

snip 05-regex-range
run "git log -s --format='%h %s' -L '/^def load/,/return rows/:scorekit/runner.py'"

snip 06-two-ranges
run "git log -s --format='%h %s' -L :exact_match:scorekit/metrics.py -L :normalize:scorekit/text.py"

snip 07-failure
note 'You are in the middle of an edit: three comment lines at the top of metrics.py, not committed.'
run "printf '# Scoring functions.\\n# Arguments: prediction, reference.\\n# Results lie between 0 and 1.\\n' | cat - scorekit/metrics.py > ../metrics.tmp && mv ../metrics.tmp scorekit/metrics.py"
run 'sed -n 1,4p scorekit/metrics.py'
run 'grep -n "overlap = " scorekit/metrics.py'
run "git log -s --format='%h %s' -L 14,14:scorekit/metrics.py"

snip 08-diagnose
run 'git show HEAD:scorekit/metrics.py | sed -n 14p'
run 'git blame -s -L 14,14 scorekit/metrics.py'
run 'git status --short'

snip 09-recovery
note 'Anchor the range on content instead of a line number. This works with or without local edits.'
run "git log -s --format='%h %s' -L '/overlap = /,+1:scorekit/metrics.py'"

snip 10-verification
run 'git stash push --quiet -m "comment block for metrics.py"'
run "git log -s --format='%h %s' -L 11,11:scorekit/metrics.py"
run 'git stash pop --quiet && git status --short'
lab_end
