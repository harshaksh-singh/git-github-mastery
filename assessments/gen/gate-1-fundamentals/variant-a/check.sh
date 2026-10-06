#!/usr/bin/env bash
# Read-only verification of gate 1, hands-on variant A. Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/check-lib.bash"
check_begin g1-a gate-1-fundamentals/variant-a "${1:-}"
R=tokmeter
S='Update rate table for September'
expect 'HEAD is on main' on_branch $R main
expect_eq "exactly one commit is called \"$S\"" "$(count_subject $R main "$S")" 1
c=$(id_of $R main "$S")
expect_eq 'its parent is the commit it had before' "$(git -C $R rev-parse -q --verify "$c^" 2>/dev/null)" "$(noted parent)"
expect_eq 'it is still authored by Asha' "$(git -C $R log -1 --format=%ae "$c" 2>/dev/null)" asha@example.com
want=$(printf 'input_per_1k: 0.40\noutput_per_1k: 1.20\ncached_input_per_1k: 0.10\n' | git hash-object --stdin)
expect_eq 'it contains the rate table with all three rates' "$(git -C $R rev-parse -q --verify "$c:rates.yaml" 2>/dev/null)" "$want"
expect_eq 'rates.yaml on disk has all three rates' "$(git -C $R hash-object rates.yaml 2>/dev/null)" "$want"
expect_not 'reports/last-run.json is not in the last commit' git -C $R cat-file -e HEAD:reports/last-run.json
expect_eq 'reports/last-run.json is still on disk with the result of the last run' "$(cat $R/reports/last-run.json 2>/dev/null)" '{"tokens": 18234}'
expect 'reports/last-run.json is ignored now' git -C $R check-ignore -q reports/last-run.json
expect 'tokmeter/cache.py is in the last commit' git -C $R cat-file -e HEAD:tokmeter/cache.py
expect_not 'no setting hides untracked files from git status' test "$(git -C $R config get status.showUntrackedFiles 2>/dev/null)" = no
expect 'nothing is staged, modified or untracked' clean_tree $R
check_end
