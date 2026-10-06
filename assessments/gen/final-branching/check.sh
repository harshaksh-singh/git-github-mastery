#!/usr/bin/env bash
# Read-only verification of the final-test lab "branching". Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../final-lib/check-lib.bash"
check_begin branching "${1:-}"
R=driftwatch
B=fix/window-size
expect_eq "the branch $B exists and points at the second of the two commits" "$(rev $R "refs/heads/$B")" "$(noted tip)"
expect_eq "$B starts at the release v0.3.0" "$(rev $R "refs/heads/$B~2")" "$(rev $R 'refs/tags/v0.3.0^{commit}')"
expect_eq 'main has not moved' "$(rev $R refs/heads/main)" "$(noted main)"
expect_eq 'the tag v0.3.0 has not moved' "$(rev $R refs/tags/v0.3.0)" "$(noted tag)"
expect_not 'no branch named "fix" is left' git -C $R show-ref --verify --quiet refs/heads/fix
expect 'the commit of the old branch "fix" is still reachable from main' is_ancestor $R "$(noted fix)" refs/heads/main
expect "HEAD is on $B" on_branch $R "$B"
expect 'nothing is staged, modified or untracked' clean_tree $R
check_end
