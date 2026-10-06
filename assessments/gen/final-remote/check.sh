#!/usr/bin/env bash
# Read-only verification of the final-test lab "remote". Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../final-lib/check-lib.bash"
check_begin remote "${1:-}"
R=you
B=feature/slot-carryover
expect_eq "the team's repository has $B with your two commits" "$(rev origin.git "refs/heads/$B")" "$(noted tip)"
expect_eq 'your local branch still has the same two commits' "$(rev $R "refs/heads/$B")" "$(noted tip)"
expect_eq "the upstream of $B is origin/$B" "$(git -C $R rev-parse --abbrev-ref "$B@{upstream}" 2>/dev/null)" "origin/$B"
expect_eq "a bare git push on $B now goes to origin/$B" "$(git -C $R rev-parse --abbrev-ref "$B@{push}" 2>/dev/null)" "origin/$B"
expect_not "staging no longer has the branch $B" git -C staging.git show-ref --verify --quiet "refs/heads/$B"
expect_eq 'main on staging has not moved' "$(rev staging.git refs/heads/main)" "$(noted staging_main)"
expect_eq "main on the team's repository has not moved" "$(rev origin.git refs/heads/main)" "$(noted origin_main)"
pd=$(git -C $R config get remote.pushDefault 2>/dev/null)
if [ -z "$pd" ] || [ "$pd" = origin ]; then ok 'remote.pushDefault no longer sends pushes to staging'; else bad "remote.pushDefault is still \"$pd\""; fi
expect 'the remote "staging" is still configured (the demo environment needs it)' git -C $R config get remote.staging.url
check_end
