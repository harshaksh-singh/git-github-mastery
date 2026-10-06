#!/usr/bin/env bash
# Chapter 14A, section 14A.4: renames and copies are not stored. git diff infers them from content
# similarity, and the options -M, -C and --find-copies-harder decide how hard it looks.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a diff-renames
fx_scorekit || exit 1
sk_ids

snip 01-default
run "git diff --name-status $ID_PRE_PKG v0.1.0"

snip 02-no-renames
run "git diff --name-status --no-renames $ID_PRE_PKG v0.1.0"

snip 03-threshold
run "git diff --name-status -M90% $ID_PRE_PKG v0.1.0"
run "git diff --name-status -M $ID_PRE_PKG v0.1.0 -- run_eval.py scorekit/runner.py"

snip 04-patch
run "git diff $ID_PRE_PKG v0.1.0 -- run_eval.py scorekit/runner.py"

snip 05-stat
run "git diff --stat $ID_PRE_PKG v0.1.0"

snip 06-copies
run "git show --stat --format='%h %s' $ID_NIGHTLY"
run "git show --stat --format='%h %s' -C $ID_NIGHTLY"
run "git show --stat --format='%h %s' --find-copies-harder $ID_NIGHTLY"
run "git show --name-status --format='%h %s' --find-copies-harder $ID_NIGHTLY"

snip 07-rewrite
quiet 'git mv docs/metrics.md docs/scoring.md'
tick
cat > docs/scoring.md <<'DOC'
# Scoring

Every row of a data set has a prediction and a reference. The runner averages each metric
over the rows and prints one score line.

- exact_match: 1 when prediction and reference are equal after normalization, else 0.
- token_f1: harmonic mean of token precision and recall.
- rouge_l: F-measure of the longest common subsequence of tokens.

The exit status compares exact_match with the pass mark in scorekit/config.py.
See scorekit/text.py for what normalization does.
DOC
quiet 'git add -A'
note 'docs/metrics.md was renamed to docs/scoring.md and half of its text rewritten, in one step.'
run 'git status --short'
run 'git diff --cached --name-status -M40%'
lab_end
