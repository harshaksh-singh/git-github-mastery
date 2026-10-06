#!/usr/bin/env bash
# Read-only verification of gate 4, hands-on variant B. Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/check-lib.bash"
check_begin g4-b gate-4-recovery/variant-b "${1:-}"
R=asha
expect_eq 'the tag "culprit" names the commit that changed the effective timeout' "$(git -C $R rev-parse -q --verify 'refs/tags/culprit^{commit}' 2>/dev/null)" "$(noted culprit)"
expect_not 'no bisect or other operation is in progress' in_progress $R
expect 'HEAD is on main' on_branch $R main
expect_eq 'main is exactly one commit ahead of origin/main' "$(git -C $R rev-list --count origin/main..main 2>/dev/null) $(git -C $R rev-parse -q --verify 'main~1' 2>/dev/null)" "1 $(noted main)"
expect 'that commit is a revert that names the culprit' sh -c "git -C $R log -1 --format=%b main | grep -Fq 'This reverts commit $(noted culprit)'"
expect 'the retry multiplier is 1 again' sh -c "git -C $R show main:probe/retry.py | grep -Fxq 'RETRY_MULTIPLIER = 1'"
expect 'the jitter setting is still there' sh -c "git -C $R show main:probe/retry.py | grep -Fxq 'JITTER_MS = 20'"
expect_eq 'probe/config.py was not changed' "$(git -C $R rev-parse -q --verify main:probe/config.py 2>/dev/null)" "$(git -C $R rev-parse -q --verify origin/main:probe/config.py 2>/dev/null)"
expect_eq 'the branch spike/histogram is back with both commits' "$(git -C $R rev-parse -q --verify refs/heads/spike/histogram 2>/dev/null)" "$(noted spike)"
expect_eq 'main on the server has not moved' "$(git -C server.git rev-parse -q --verify refs/heads/main 2>/dev/null)" "$(noted main)"
expect 'nothing is staged, modified or untracked' clean_tree $R
check_end
