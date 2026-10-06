#!/usr/bin/env bash
# Read-only verification of exercise 11.10. Exit status 0 means done.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
check_begin m11-vecindex vecindex/.git "${1:-}"
R=vecindex
fix=$(id_of $R v2.4.0 'Clamp top_k to the index size')
have=$(git -C $R rev-parse -q --verify 'refs/tags/answer/fix^{commit}' 2>/dev/null)
same 'the tag answer/fix names the fix on main' "$have" "$fix"
expect 'vecindex/search.py on release/2.3 equals the fixed file on main' git -C $R diff --quiet main release/2.3 -- vecindex/search.py
expect 'the earlier partial backport is still part of release/2.3' sh -c "git -C $R log --author='Ravi Menon' --format=%s release/2.3 | grep -Fxq 'Clamp top_k to the index size'"
expect 'v2.3.1 is an ancestor of release/2.3' git -C $R merge-base --is-ancestor v2.3.1 release/2.3
expect 'the backport records where it came from (cherry picked from ...)' sh -c "git -C $R log --format=%b v2.3.1..release/2.3 | grep -q \"cherry picked from commit $fix\""
expect_not 'main was not merged into release/2.3' git -C $R merge-base --is-ancestor "$(id_of $R main 'Add recall@k metric')" release/2.3
same 'v2.3.2 is an annotated tag' "$(git -C $R cat-file -t refs/tags/v2.3.2 2>/dev/null)" tag
same 'v2.3.2 names the tip of release/2.3' "$(git -C $R rev-parse -q --verify 'v2.3.2^{commit}' 2>/dev/null)" "$(git -C $R rev-parse release/2.3)"
same 'v2.3.1 still names the commit it was released from' "$(git -C $R log -1 --format=%s v2.3.1)" 'Close the index file on error'
expect 'no operation is left in progress' no_operation $R
check_end
