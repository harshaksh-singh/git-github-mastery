#!/usr/bin/env bash
# Chapter 14A, section 14A.9: git log walks a graph. --graph draws it, --first-parent follows the
# main line only, --merges and --no-merges filter by parent count, --simplify-by-decoration keeps
# only the commits that carry a ref.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a log-graph
fx_scorekit || exit 1
sk_ids

snip 01-graph-range
run "git log --graph --oneline $ID_PUNCT~1..$ID_MERGE"

snip 02-first-parent
run "git log --oneline --first-parent $ID_PUNCT~1..$ID_MERGE"

snip 03-merges
run 'git log --oneline --merges'
run 'git rev-list --count v0.1.0..main'
run 'git rev-list --count --first-parent v0.1.0..main'
run 'git rev-list --count --no-merges v0.1.0..main'

snip 04-decoration
run 'git log --graph --oneline --decorate --simplify-by-decoration --all'
lab_end
