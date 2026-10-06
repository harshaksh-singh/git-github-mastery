#!/usr/bin/env bash
# Read-only verification of gate 1, hands-on variant B. Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/check-lib.bash"
check_begin g1-b gate-1-fundamentals/variant-b "${1:-}"
R=shardmap
S='Add shard weights'
expect 'HEAD is on main' on_branch $R main
expect_eq "exactly one commit is called \"$S\"" "$(count_subject $R refs/heads/main "$S")" 1
c=$(id_of $R refs/heads/main "$S")
expect_eq 'its parent is the commit it had before' "$(git -C $R rev-parse -q --verify "$c^" 2>/dev/null)" "$(noted parent)"
expect_eq 'it is still authored by Ravi' "$(git -C $R log -1 --format=%ae "$c" 2>/dev/null)" ravi@example.com
expect_eq 'it contains shardmap/hashing.py as it was committed before' "$(git -C $R rev-parse -q --verify "$c:shardmap/hashing.py" 2>/dev/null)" "$(noted hashing)"
expect 'it contains shardmap/weights.py' git -C $R cat-file -e "$c:shardmap/weights.py"
expect 'the half-done edit of shardmap/hashing.py is still in the working tree' grep -q blake2b $R/shardmap/hashing.py
expect_eq 'the half-done edit is not committed' "$(git -C $R rev-parse -q --verify HEAD:shardmap/hashing.py 2>/dev/null)" "$(noted hashing)"
expect_eq 'scripts/rebalance.sh is executable in the last commit' "$(git -C $R ls-tree HEAD scripts/rebalance.sh 2>/dev/null | cut -c1-6)" 100755
expect_not 'the name "main" is not ambiguous' sh -c "git -C $R rev-parse main 2>&1 | grep -q ambiguous"
expect_eq 'the name "main" resolves to the branch' "$(git -C $R rev-parse -q --verify main 2>/dev/null)" "$(git -C $R rev-parse -q --verify refs/heads/main 2>/dev/null)"
expect_eq 'the half-done edit is the only change that git status reports' "$(git -C $R -c core.fileMode=true status --porcelain --untracked-files=all 2>/dev/null)" ' M shardmap/hashing.py'
check_end
