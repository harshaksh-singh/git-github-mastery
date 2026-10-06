#!/usr/bin/env bash
# Read-only verification of exercise 12.9. Exit status 0 means recovered.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
check_begin m12-batchscore ravi/.git "${1:-}"
R=ravi; B=feature/retry-budget
for s in 'Add retry budget' 'Spend the budget per batch' 'Refuse to retry when the budget is spent' 'Log the retry budget at startup'; do
  same "the commit \"$s\" is on $B exactly once" "$(count_subject $R $B "$s")" 1
done
same 'this morning'"'"'s commit is the tip of the branch' "$(git -C $R log -1 --format=%s $B 2>/dev/null)" 'Log the retry budget at startup'
expect 'the branch contains the current main of the server' git -C $R merge-base --is-ancestor "$(git -C server.git rev-parse refs/heads/main)" $B
expect 'the worker has the final form of the budget check (<= 0)' sh -c "git -C $R show $B:batchscore/worker.py | grep -q 'budget.left <= 0'"
expect 'the budget class is back' sh -c "git -C $R show $B:batchscore/budget.py | grep -q 'def spend'"
same 'HEAD is on the branch' "$(git -C $R symbolic-ref -q --short HEAD)" $B
same 'the working tree is clean' "$(git -C $R status --porcelain | wc -l | tr -d ' ')" 0
expect 'no operation is left in progress' no_operation $R
check_end
