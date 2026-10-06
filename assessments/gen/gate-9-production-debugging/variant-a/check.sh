#!/usr/bin/env bash
# Read-only verification of gate 9, hands-on variant A. Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/check-lib.bash"
check_begin g9-a gate-9-production-debugging/variant-a "${1:-}"
S=server.git; B=refs/heads/release/2.2
tip() { git -C $S rev-parse -q --verify "$1" 2>/dev/null; }
expect 'the history of release/2.2 on the server was not rewritten' git -C $S merge-base --is-ancestor "$(noted tip)" $B
expect_not 'release/2.2 no longer contains the wallet feature' git -C $S cat-file -e $B:checkout/wallet.py
expect_not 'release/2.2 no longer contains the 2.3 changelog' git -C $S cat-file -e $B:docs/CHANGELOG.md
expect_eq 'checkout/total.py on release/2.2 is the file of v2.2.1' "$(tip $B:checkout/total.py)" "$(tip "$(noted v221):checkout/total.py")"
expect_eq 'release/2.2 has the rounding fix' "$(tip $B:checkout/rounding.py)" "$(noted fixblob)"
expect "Ravi's commit is still on release/2.2" git -C $S cat-file -e $B:Dockerfile
expect 'a commit on release/2.2 reverts the merge and names it' sh -c "git -C $S log --format=%b $(noted tip)..$B | grep -Fq 'This reverts commit $(noted merge)'"
expect 'the fix on release/2.2 names the commit on main it was copied from' sh -c "git -C $S log --format=%b $(noted tip)..$B | grep -Fxq '(cherry picked from commit $(noted fix))'"
expect_eq 'no further merge was added to release/2.2' "$(git -C $S rev-list --count --merges "$(noted tip)..$B" 2>/dev/null)" 0
expect_eq 'main on the server has not moved' "$(tip refs/heads/main)" "$(noted main)"
expect_eq 'the tag v2.2.1 has not moved' "$(tip 'refs/tags/v2.2.1^{commit}')" "$(noted v221)"
expect_eq 'your release/2.2 equals the server' "$(git -C you rev-parse -q --verify refs/heads/release/2.2 2>/dev/null)" "$(tip $B)"
expect 'nothing is staged, modified or untracked in you/' clean_tree you
expect_not 'no operation is left in progress' in_progress you
check_end
