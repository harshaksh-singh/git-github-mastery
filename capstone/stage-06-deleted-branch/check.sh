#!/usr/bin/env bash
# Read-only verification of capstone stage 6. Exit status 0 means the Git state is as required.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/check-lib.bash"
check_begin 6 "${1:-}"
B=feature/multilingual-intents

expect "the server has the branch $B again" git -C $S rev-parse --verify -q refs/heads/$B
for s in 'Add Hindi keyword lists' 'Add Tamil keyword lists' 'Pick the keyword lists by detected language'; do
  once "\"$s\" is on the branch" $S main..$B "$s"
done
n=$(git -C $S rev-list --count main..$B 2>/dev/null)
if [ "$n" = 3 ]; then ok 'the branch has exactly the three commits that main does not have'; else bad "the branch has ${n:-no} commits that main does not have (expected 3)"; fi
expect 'the branch has the last version of router/lang.py' sh -c "git -C $S show $B:router/lang.py | grep -q 'def keywords_for'"
expect 'the test suite passes on the branch' tests_pass $S $B
n=$(pr_of $B)
if [ "$(pr_state "$n")" = open ]; then ok "pull request #$n is open again"; else bad "pull request #$n is $(pr_state "$n"), not open (../pr reopen)"; fi
expect 'main on the server was not touched by the recovery' sh -c "git -C $S log -1 --format=%s main | grep -Eq '\\(#[0-9]+\\)\$|^Merge pull request #'"
check_end
