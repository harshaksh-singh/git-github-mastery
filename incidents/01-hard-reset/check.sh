#!/usr/bin/env bash
# Read-only verification of the recovery of incident 1. Exit status 0 means recovered.
. "$(dirname "${BASH_SOURCE[0]}")/../lib/check-lib.bash"
check_begin 01-hard-reset "${1:-}"
B=feature/escalation-rules
for s in 'Add escalation predicate' 'Route escalated tickets to the on-call queue' 'Never escalate spam'; do
  expect "the commit \"$s\" is on $B again" has_subject ravi "$B" "$s"
done
expect 'the commit made after the reset is still on the branch' has_subject ravi "$B" 'Mention escalation in the README'
n=$(git -C ravi log --format=%s "$B" 2>/dev/null | grep -Fxc 'Document how to run the tests')
if [ "$n" = 1 ]; then ok 'no commit of main was copied'; else bad "the main commit \"Document how to run the tests\" appears $n times on $B (expected once)"; fi
expect 'the branch contains the current origin/main' git -C ravi merge-base --is-ancestor origin/main "$B"
expect 'triage/escalate.py in the last commit has the spam rule' sh -c "git -C ravi show $B:triage/escalate.py | grep -q is_spam"
want=$(printf 'outage: 1\nbilling: 2\nhow-to: 3\n' | git hash-object --stdin)
have=$(git -C ravi hash-object rules/priority.yaml 2>/dev/null)
if [ "$want" = "$have" ]; then ok 'the staged file rules/priority.yaml is back with its content'; else bad 'rules/priority.yaml (staged, never committed) is not back in the working tree with its content'; fi
expect_not 'no operation is left in progress' sh -c 'ls ravi/.git/CHERRY_PICK_HEAD ravi/.git/MERGE_HEAD ravi/.git/rebase-merge ravi/.git/rebase-apply 2>/dev/null | grep -q .'
check_end
