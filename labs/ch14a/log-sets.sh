#!/usr/bin/env bash
# Chapter 14A, section 14A.14: set questions on the graph: which side has what (--left-right),
# without copies (--cherry-pick), through which commits did a change reach a tip (--ancestry-path),
# and what do only the reflogs still know (--reflog).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a log-sets
fx_scorekit || exit 1
sk_ids

snip 01-left-right
run 'git log --oneline --left-right main...feat/report'
run 'git log --oneline --left-right --cherry-pick main...feat/report'

snip 02-plain-range
note "$ID_MOVE moved normalize() into its own module, on a side branch. Everything v0.2.0 has that $ID_MOVE lacks:"
run "git log --oneline $ID_MOVE..v0.2.0"

snip 03-ancestry-path
note "Only the commits that are descendants of $ID_MOVE as well: the path the change travelled."
run "git log --oneline --ancestry-path $ID_MOVE..v0.2.0"

snip 04-which-merge
run "git log --oneline --merges --ancestry-path $ID_MOVE..main | tail -n 1"

snip 05-reflog
quiet "git commit --amend -m 'Describe the nightly job in the README'"
run "git log --oneline --all --grep='nightly run'"
run "git log --oneline --reflog --grep='nightly run'"
run 'git log --oneline -g -2'
lab_end
