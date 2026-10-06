#!/usr/bin/env bash
# Chapter 14A, section 14A.19: the method, on regression 1. Locate the code, blame it, read the
# commit, confirm with the pickaxe, and establish which releases and branches contain the commit.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a find-origin
fx_scorekit || exit 1
sk_ids

snip 01-symptom
run_rc 'python3 -B -m scorekit.runner data/smoke.jsonl'
run 'git grep -n "exact_match" -- docs'
run 'git grep -n -W "def exact_match"'

snip 02-locate
run 'git grep -n "def normalize"'
run 'git blame --date=short -L :normalize scorekit/text.py'

snip 03-through-the-formatter
run "git blame --date=short --ignore-rev $ID_REFORMAT -L :normalize scorekit/text.py"

snip 04-read
run "git show $ID_R1"

snip 05-confirm
run "git log --format='%h %ad %<(10)%an %s' --date=short -S'.lower()'"

snip 06-test-both-sides
note 'One call that separates right from wrong, at the suspect and at its parent, without touching the working tree:'
run "git worktree add --detach --quiet ../before $ID_R1~1"
run "git worktree add --detach --quiet ../after $ID_R1"
run "(cd ../before && python3 -B -c 'from scorekit.metrics import exact_match; print(exact_match(\"Paris\", \"paris\"))')"
run "(cd ../after && python3 -B -c 'from scorekit.metrics import exact_match; print(exact_match(\"Paris\", \"paris\"))')"
run 'git worktree remove ../before && git worktree remove ../after'

snip 07-blast-radius
run "git tag --contains $ID_R1"
run "git branch --all --contains $ID_R1"
run "git describe --contains $ID_R1"
run "git log --oneline $ID_R1..main -- scorekit/text.py"
lab_end
