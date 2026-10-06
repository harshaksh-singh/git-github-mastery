#!/usr/bin/env bash
# Read-only verification of exercise 15.9. Exit status 0 means done.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
check_begin m15-evalboard you/.git "${1:-}"
R=you; S=remotes/evalboard.git
want=$(git -C remotes/metrickit.git rev-parse 'v0.2.0^{commit}')
same 'the tag answer/rollback names the commit that moved the pointer back' "$(git -C $R rev-parse -q --verify 'refs/tags/answer/rollback^{commit}' 2>/dev/null)" "$(id_of $R main 'Sort runs by date')"
same 'main records metrickit 0.2.0 again' "$(git -C $R rev-parse -q --verify main:vendor/metrickit 2>/dev/null)" "$want"
expect 'nothing was rewritten (the 0.5.0 commit is an ancestor of main)' git -C $R merge-base --is-ancestor "$(id_of $R main 'Bump dashboard version to 0.5.0')" main
same 'the fix is pushed' "$(git -C $S rev-parse -q --verify refs/heads/main)" "$(git -C $R rev-parse main)"
same 'the submodule is checked out at the recorded commit' "$(git -C $R submodule status 2>/dev/null | cut -c1-41)" " $want"
same 'the working tree of the superproject is clean' "$(git -C $R status --porcelain | wc -l | tr -d ' ')" 0
same 'submodule.recurse is true in your clone' "$(git -C $R config get --local submodule.recurse 2>/dev/null)" true
check_end
