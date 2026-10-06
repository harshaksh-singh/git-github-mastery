#!/usr/bin/env bash
# Read-only verification of the final-test lab "fork". Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../final-lib/check-lib.bash"
check_begin fork "${1:-}"
R=you
B=fix/utc-timestamps
up=$(noted upstream)
expect_eq 'the project (upstream.git) was not touched' "$(rev upstream.git refs/heads/main)" "$up"
expect_eq 'your clone has a remote "upstream" that points at the project' "$(git -C $R config get remote.upstream.url 2>/dev/null)" ../upstream.git
expect_eq 'main in your fork equals main of the project' "$(rev fork.git refs/heads/main)" "$up"
expect_eq 'your local main equals main of the project' "$(rev $R refs/heads/main)" "$up"
expect "the fork has the branch $B, based on the project's current main" is_ancestor fork.git "$up" "refs/heads/$B"
expect_eq "$B holds exactly your two commits, in order" "$(subjects fork.git "$up..refs/heads/$B")" 'Emit UTC timestamps | Test that timestamps are UTC'
expect_eq "your local $B equals the one in the fork" "$(rev $R "refs/heads/$B")" "$(rev fork.git "refs/heads/$B")"
expect_eq "the upstream of your local $B is origin/$B" "$(git -C $R rev-parse --abbrev-ref "$B@{upstream}" 2>/dev/null)" "origin/$B"
expect 'the branch still has the UTC change' sh -c "git -C fork.git show 'refs/heads/$B:spanlog/clock.py' | grep -q gmtime"
expect 'nothing is staged, modified or untracked in your clone' clean_tree $R
expect_not 'no operation is left in progress' in_progress $R
check_end
