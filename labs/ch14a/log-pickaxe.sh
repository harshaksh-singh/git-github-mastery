#!/usr/bin/env bash
# Chapter 14A, section 14A.11: -S counts occurrences, -G matches changed lines. The same string
# gives two different lists of commits, and the commit that makes the difference is shown.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a log-pickaxe
fx_scorekit || exit 1
sk_ids

snip 01-S
run "git log --oneline -S'PASS_MARK'"

snip 02-G
run "git log --oneline -G'PASS_MARK'"

snip 03-why
run "git show --format='%h %s' $ID_RAISE"
run "git grep -c PASS_MARK $ID_RAISE~1 $ID_RAISE"

snip 04-reformat
run "git show --format='%h %s' $ID_REFORMAT -- scorekit/runner.py | grep -n PASS_MARK"

snip 05-lower
run "git log --format='%h %ad %<(10)%an %s' --date=short -S'.lower()'"
run "git log --format='%h %ad %<(10)%an %s' --date=short -G'\.lower\(\)'"

snip 06-regex
run "git log --oneline -G'PASS_MARK = 0\.[0-9]+'"
run "git log --oneline --pickaxe-regex -S'PASS_MARK = 0\.[0-9]+'"

snip 07-with-patch
run "git log -p --format='%h %s' -S'.lower()' -1"

snip 08-scope
run "git log --oneline -S'write_report'"
run "git log --oneline --all -S'write_report'"
lab_end
