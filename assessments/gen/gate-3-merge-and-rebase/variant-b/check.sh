#!/usr/bin/env bash
# Read-only verification of gate 3, hands-on variant B. Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/check-lib.bash"
check_begin g3-b gate-3-merge-and-rebase/variant-b "${1:-}"
R=asha; B=release/2.1
expect_not 'no cherry-pick is in progress' in_progress $R
expect "HEAD is on $B" on_branch $R $B
expect_eq "$B is three commits ahead of the server: the three fixes, oldest first" "$(git -C $R log --reverse --format=%s origin/$B..$B 2>/dev/null | tr '\n' '|')" 'Fix negative remaining quota|Fix window rollover at midnight UTC|Fix rounding of the quota header|'
i=0
for k in f3 f2 f1; do
  expect "the commit $B~$i names the commit on main it was picked from" sh -c "git -C $R log -1 --format=%b $B~$i | grep -Fxq '(cherry picked from commit $(noted $k))'"
  i=$((i + 1))
done
expect_not 'the burst setting is not on the release branch' sh -c "git -C $R show $B:quota/limits.py | grep -q BURST"
expect 'the release keeps its 60 second window' sh -c "git -C $R show $B:quota/window.py | grep -Fxq 'WINDOW_S = 60'"
expect 'the release has the rollover fix' sh -c "git -C $R show $B:quota/window.py | grep -Fxq 'DAY_S = 86400' && git -C $R show $B:quota/window.py | grep -Fq 'DAY_S - WINDOW_S'"
expect_not 'no conflict marker and no 3600 in quota/window.py' sh -c "git -C $R show $B:quota/window.py | grep -Eq '3600|^<<<<<<<|^=======|^>>>>>>>'"
expect 'the release has the other two fixes' sh -c "git -C $R show $B:quota/check.py | grep -q 'max(limit - used, 0)' && git -C $R show $B:quota/headers.py | grep -q round"
expect_eq 'release/2.1 on the server has not moved' "$(git -C server.git rev-parse -q --verify refs/heads/$B 2>/dev/null)" "$(noted release)"
expect_eq 'main has not moved' "$(git -C $R rev-parse -q --verify refs/heads/main 2>/dev/null)" "$(noted main)"
expect 'nothing is staged, modified or untracked' clean_tree $R
check_end
