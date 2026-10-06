#!/usr/bin/env bash
# Read-only verification of exercise 12.11. Exit status 0 means recovered.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
check_begin m12-feedbackloop ravi/.git "${1:-}"
R=ravi; B=feature/dedupe-feedback
LAB_ERA_END=1789965000        # two weeks after the start of the lab clock; later commits are copies
n=4
for s in 'Add feedback fingerprint' 'Drop duplicate feedback by fingerprint' 'Keep the newest of two duplicates' 'Count dropped duplicates'; do
  same "\"$s\" is commit number $((5 - n)) of the branch" "$(git -C $R log -1 --format=%s "$B~$n" 2>/dev/null)" "$s"
  ct=$(git -C $R log -1 --format=%ct "$B~$n" 2>/dev/null)
  if [ -n "$ct" ] && [ "$ct" -lt "$LAB_ERA_END" ]; then ok '  and it is the original commit object, not a copy'; else bad '  and it is the original commit object, not a copy'; fi
  n=$((n - 1))
done
same 'the fifth commit is the one from the mailed patch' "$(git -C $R log -1 --format=%s $B 2>/dev/null)" 'Skip feedback older than the retention window'
same '  with Ravi as its author' "$(git -C $R log -1 --format=%ae $B 2>/dev/null)" ravi@example.com
at=$(git -C $R log -1 --format=%at $B 2>/dev/null)
if [ -n "$at" ] && [ "$at" -lt "$LAB_ERA_END" ]; then ok '  and its original author date'; else bad '  and its original author date'; fi
same 'the branch has exactly five commits on top of main' "$(git -C $R rev-list --count main..$B 2>/dev/null)" 5
expect 'the retention module is in the tree' git -C $R cat-file -e $B:feedbackloop/retention.py
same 'the server has the branch again, at the same commit' "$(git -C server.git rev-parse -q --verify refs/heads/$B 2>/dev/null)" "$(git -C $R rev-parse -q --verify refs/heads/$B 2>/dev/null)"
expect 'no operation is left in progress in Ravi'"'"'s clone' no_operation $R
check_end
