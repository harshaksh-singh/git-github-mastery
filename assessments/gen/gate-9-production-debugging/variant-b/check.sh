#!/usr/bin/env bash
# Read-only verification of gate 9, hands-on variant B. Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/check-lib.bash"
check_begin g9-b gate-9-production-debugging/variant-b "${1:-}"
S=server.git; R=refs/heads/release/3.1
SUBJ='Clamp negative quantities in the line total'
tip() { git -C $S rev-parse -q --verify "$1" 2>/dev/null; }
expect_eq 'release/3.1 exists on the server and starts at v3.1.0' "$(git -C $S merge-base "$(noted v310)" $R 2>/dev/null)" "$(noted v310)"
expect_eq 'release/3.1 has exactly one commit on top of v3.1.0: the fix' "$(git -C $S log --format=%s "$(noted v310)..$R" 2>/dev/null)" "$SUBJ"
expect 'that commit names the commit of 3.0.1 it was copied from' sh -c "git -C $S log -1 --format=%b $R | grep -Fxq '(cherry picked from commit $(noted fix))'"
expect 'release/3.1 has the clamp in cart/pricing.py' sh -c "git -C $S show $R:cart/pricing.py | grep -Fq 'max(qty, 0)'"
expect_eq 'the tag v3.1.1 is an annotated tag' "$(git -C $S cat-file -t refs/tags/v3.1.1 2>/dev/null)" tag
expect_eq 'v3.1.1 names the tip of release/3.1' "$(tip 'refs/tags/v3.1.1^{commit}')" "$(tip $R)"
expect 'main on the server was extended, not rewritten' git -C $S merge-base --is-ancestor "$(noted main)" refs/heads/main
expect 'main on the server has the clamp' sh -c "git -C $S show refs/heads/main:cart/pricing.py | grep -Fq 'max(qty, 0)'"
expect_eq 'the dependency bump is still on main' "$(git -C $S show refs/heads/main:requirements.txt 2>/dev/null)" 'pricing-lib==4.2'
expect 'coupon support is still on main' git -C $S cat-file -e refs/heads/main:cart/coupons.py
expect_not 'main has no file under the old module name' git -C $S cat-file -e refs/heads/main:cart/total.py
expect_eq 'the tags v3.0.1 and v3.1.0 have not moved' "$(tip 'refs/tags/v3.0.1^{commit}') $(tip 'refs/tags/v3.1.0^{commit}')" "$(noted v301) $(noted v310)"
expect 'nothing is staged, modified or untracked in you/' clean_tree you
expect_not 'no operation is left in progress' in_progress you
check_end
