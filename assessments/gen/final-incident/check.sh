#!/usr/bin/env bash
# Read-only verification of the final-test lab "incident". Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../final-lib/check-lib.bash"
check_begin incident "${1:-}"
S=server.git
fix=$(noted fix)
new=$(rev $S refs/heads/main)
expect_eq 'exactly one new commit sits on top of the commit released as 1.5.0' "$(rev $S 'refs/heads/main~1')" "$(noted main)"
expect 'that commit records where the fix came from (cherry-pick -x)' sh -c "git -C $S log -1 --format=%B refs/heads/main | grep -Fq '(cherry picked from commit $fix)'"
expect 'budget.py on main has the fixed comparison' sh -c "git -C $S show main:budget.py | grep -Fq 'return used <= limit'"
expect_eq 'the new commit changes budget.py and nothing else' "$(git -C $S diff --name-only 'refs/heads/main~1' refs/heads/main 2>/dev/null)" budget.py
expect_eq 'v1.5.1 on the server is an annotated tag' "$(git -C $S cat-file -t refs/tags/v1.5.1 2>/dev/null)" tag
expect_eq 'v1.5.1 names the new commit' "$(rev $S 'refs/tags/v1.5.1^{commit}')" "$new"
expect_eq 'the tag v1.5.0 has not moved' "$(rev $S refs/tags/v1.5.0)" "$(noted v150)"
expect_eq 'the tag v1.4.1 has not moved' "$(rev $S refs/tags/v1.4.1)" "$(noted v141)"
expect_eq 'release/1.4 has not moved' "$(rev $S refs/heads/release/1.4)" "$(noted release)"
expect_eq 'your main equals main on the server' "$(rev you refs/heads/main)" "$new"
expect 'nothing is staged, modified or untracked in your clone' clean_tree you
expect_not 'no operation is left in progress' in_progress you
check_end
