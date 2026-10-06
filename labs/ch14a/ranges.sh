#!/usr/bin/env bash
# Chapter 14A, section 14A.8: the range forms of gitrevisions as set operations on the commit graph:
# A..B, ^A B, --not, A...B, A^!, A^@ and A^-.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a ranges
fx_scorekit || exit 1
sk_ids

snip 01-two-dots
run 'git log --oneline main..feat/report'
run 'git log --oneline ^main feat/report'
run 'git log --oneline feat/report --not main'

snip 02-other-way
run 'git log --oneline feat/report..main'

snip 03-three-dots
run 'git log --oneline main...feat/report'
run 'git log --oneline --left-right main...feat/report'
run 'git log --oneline --graph --boundary main...feat/report'

snip 04-several
note 'Everything that is on some branch and not yet in main, in one query:'
run 'git log --oneline --branches --not main'
run 'git rev-list --count v0.1.0..main'

snip 05-parents
run "git rev-parse $ID_MERGE^@"
run "git log --oneline $ID_MERGE^!"
run "git log --oneline $ID_MERGE^-"
run "git log --oneline $ID_MERGE^1..$ID_MERGE"

snip 06-one-commit-diff
run "git diff --stat $ID_R2^!"
run "git diff --stat $ID_R2~1 $ID_R2"

snip 07-empty-range
run 'git log --oneline main..v0.2.0'
run 'git merge-base --is-ancestor v0.2.0 main && echo "v0.2.0 is an ancestor of main"'
lab_end
