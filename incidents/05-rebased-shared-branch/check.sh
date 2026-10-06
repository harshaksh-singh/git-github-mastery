#!/usr/bin/env bash
# Read-only verification of the recovery of incident 5. Exit status 0 means recovered.
. "$(dirname "${BASH_SOURCE[0]}")/../lib/check-lib.bash"
check_begin 05-rebased-shared-branch "${1:-}"
S=server.git
B=feature/online-serving
expect 'the server still has the branch' git -C $S rev-parse --verify -q refs/heads/$B
for s in 'Add online lookup' 'Decode online values' 'Add cache warm-up job' 'Add batched online lookup' 'Decode batched values'; do
  n=$(git -C $S log --format=%s main..$B 2>/dev/null | grep -Fxc "$s")
  if [ "$n" = 1 ]; then ok "\"$s\" is on the branch exactly once"; else bad "\"$s\" is on the branch $n times (expected once)"; fi
done
n=$(git -C $S rev-list --count main..$B 2>/dev/null)
if [ "$n" = 5 ]; then ok 'the branch has five commits that main does not have'; else bad "the branch has $n commits that main does not have (expected 5)"; fi
n=$(git -C $S rev-list --count --merges main..$B 2>/dev/null)
if [ "$n" = 0 ]; then ok 'the branch contains no merge commit'; else bad "the branch contains $n merge commit(s)"; fi
expect 'the branch is based on the current main' git -C $S merge-base --is-ancestor main $B
expect 'store/batch.py decodes values' sh -c "git -C $S show $B:store/batch.py | grep -q decode"
expect 'store/warm.py is on the branch' git -C $S cat-file -e $B:store/warm.py
tip=$(git -C $S rev-parse $B 2>/dev/null)
for c in you asha; do
  if [ "$(git -C $c rev-parse -q --verify refs/heads/$B)" = "$tip" ]; then ok "the branch in $c/ equals the branch on the server"; else bad "the branch in $c/ differs from the branch on the server"; fi
done
check_end
