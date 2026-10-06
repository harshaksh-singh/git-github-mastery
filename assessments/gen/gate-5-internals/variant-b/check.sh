#!/usr/bin/env bash
# Read-only verification of gate 5, hands-on variant B. Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/check-lib.bash"
check_begin g5-b gate-5-internals/variant-b "${1:-}"
R=asha
export GIT_NO_LAZY_FETCH=1             # the check must not download anything
expect 'HEAD is on main' on_branch $R main
expect_eq "main names Asha's unpushed commit" "$(git -C $R rev-parse -q --verify refs/heads/main 2>/dev/null)" "$(noted head)"
expect 'the index can be read and equals HEAD' git -C $R diff --cached --quiet
expect_eq 'the README edit is still in the working tree' "$(git -C $R hash-object README.md 2>/dev/null)" "$(noted readme)"
expect_eq 'git status reports the README edit, unstaged, and nothing else' "$(git -C $R status --porcelain --untracked-files=all 2>/dev/null)" ' M README.md'
expect 'the remote origin can be reached' git -C $R ls-remote --exit-code origin refs/heads/main
expect_eq 'the clone is still a partial clone of origin' "$(git -C $R config get remote.origin.promisor 2>/dev/null) $(git -C $R config get remote.origin.partialclonefilter 2>/dev/null)" 'true blob:none'
expect 'the 1.0.0 schema can be read without the network' git -C $R cat-file -e v1.0.0:shardlog/schema.py
expect_eq 'git fsck reports nothing' "$(git -C $R fsck --no-dangling 2>&1; echo "rc=$?")" 'rc=0'
expect_eq 'the server has not been changed' "$(git -C server.git rev-parse -q --verify refs/heads/main 2>/dev/null)" "$(noted server_main)"
check_end
