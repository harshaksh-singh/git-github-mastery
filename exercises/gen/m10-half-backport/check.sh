#!/usr/bin/env bash
# Read-only verification of Exercise 10.10. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m10-half-backport "${1:-}"
S=server.git; B=refs/heads/release/2.x; M=refs/heads/main
T='Route prompts of exactly the limit to the large model'
expect 'release/2.x on the server still contains the released history' git -C $S merge-base --is-ancestor "$(noted release_tip)" $B
expect_eq 'the routing code of the release equals the routing code of main' "$(git -C $S rev-parse -q --verify $B:router/select.py)" "$(git -C $S rev-parse -q --verify $M:router/select.py)"
expect_eq 'the follow-up fix is on the release line exactly once' "$(count_subject $S $B "$T")" 1
src=$(id_of $S $M "$T"); c=$(id_of $S $B "$T")
expect 'the backport records the commit of main it came from' sh -c "git -C $S log -1 --format=%b ${c:-HEAD} | grep -Fxq '(cherry picked from commit $src)'"
expect_not 'cost-aware routing was not backported' sh -c "git -C $S show $B:router/cost.py | grep -q cheapest"
expect_eq 'no merge was made into the release line' "$(git -C $S rev-list --merges --count "$(noted release_tip)"..$B 2>/dev/null)" 0
expect_eq 'your local release/2.x is what the server has' "$(git -C you rev-parse -q --verify $B)" "$(git -C $S rev-parse -q --verify $B)"
expect_not 'nothing is left in progress in your clone' in_progress you
expect 'your working tree is clean' clean_tree you
check_end
