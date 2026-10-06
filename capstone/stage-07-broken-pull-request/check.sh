#!/usr/bin/env bash
# Read-only verification of capstone stage 7. Exit status 0 means the Git state is as required.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/check-lib.bash"
check_begin 7 "${1:-}"
B=feature/vip-escalation

expect "the server still has the branch $B" git -C $S rev-parse --verify -q refs/heads/$B
for s in 'Add the VIP customer list' 'Escalate VIP messages that would fall back' 'Test the VIP escalation' \
         'Document the VIP escalation' 'Escalate VIP messages without any intent as well'; do
  n=$(count_subject $S main..$B "$s")
  if [ "$n" = 1 ]; then ok "\"$s\" is on the branch exactly once"; else bad "\"$s\" is on the branch $n times (expected once)"; fi
done
n=$(git -C $S rev-list --count main..$B 2>/dev/null)
if [ "$n" = 5 ]; then ok 'the branch has five commits that main does not have'; else bad "the branch has ${n:-no} commits that main does not have (expected 5)"; fi
n=$(git -C $S rev-list --count --merges main..$B 2>/dev/null)
if [ "$n" = 0 ]; then ok 'the branch contains no merge commit'; else bad "the branch contains ${n:-?} merge commit(s)"; fi
expect 'the branch is based on the current main' git -C $S merge-base --is-ancestor main $B
expect 'the test suite passes on the branch' tests_pass $S $B
expect 'the review commit of the tech lead is in the README' sh -c "git -C $S show $B:README.md | grep -q '^## VIP customers'"
expect 'the change that was only in your clone is in the file' sh -c "git -C $S show $B:router/vip.py | grep -q 'intent in (None, fallback)'"
n=$(pr_of $B)
if [ "$(pr_state "$n")" = open ]; then ok "pull request #$n is open"; else bad "pull request #$n is $(pr_state "$n"); this stage repairs it and leaves the merge to the reviewer"; fi
tip=$(git -C $S rev-parse -q --verify refs/heads/$B)
for c in you nandini kabir; do
  if [ -n "$tip" ] && [ "$(git -C $c rev-parse -q --verify refs/heads/$B)" = "$tip" ]; then ok "the branch in $c/ equals the branch on the server"; else bad "the branch in $c/ differs from the branch on the server"; fi
  expect_not "no rebase, merge or cherry-pick is left in progress in $c/" in_progress $c
done
check_end
