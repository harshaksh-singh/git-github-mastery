#!/usr/bin/env bash
# Read-only verification of capstone stage 5. Exit status 0 means the Git state is as required.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/check-lib.bash"
check_begin 5 "${1:-}"
B=feature/routing-metrics

expect "the server has the branch $B (the work is no longer on one laptop only)" git -C $S rev-parse --verify -q refs/heads/$B
for s in 'Add routing counters' 'Count fallbacks per tenant' 'Render the counters as text'; do
  once "\"$s\" is on $B on the server" $S main..$B "$s"
done
expect "router/metrics.py on $B has the last version of the counters" \
  sh -c "git -C $S show $B:router/metrics.py | grep -q 'def render' && git -C $S show $B:router/metrics.py | grep -q fallbacks_by_tenant"
expect "the test suite passes on $B" tests_pass $S $B
expect 'main on the server was not touched by the recovery' sh -c "git -C $S log -1 --format=%s main | grep -Eq '\\(#[0-9]+\\)\$|^Merge pull request #'"
if [ "$(git -C tanvi rev-parse -q --verify refs/heads/main)" = "$(git -C $S rev-parse main)" ]; then
  ok "main in tanvi/ equals main on the server"; else bad "main in tanvi/ differs from main on the server"; fi
if [ "$(git -C tanvi rev-parse -q --verify refs/heads/$B)" = "$(git -C $S rev-parse -q --verify refs/heads/$B)" ]; then
  ok "$B in tanvi/ equals the branch on the server"; else bad "$B in tanvi/ differs from the branch on the server"; fi
want=$(printf 'groups:\n- name: intent-router\n  rules:\n  - alert: FallbackRateHigh\n    expr: rate(fallbacks[10m]) / rate(routed[10m]) > 0.4\n    for: 15m\n' | git hash-object --stdin)
have=$(git -C tanvi hash-object deploy/alerts.yaml 2>/dev/null)
if [ "$want" = "$have" ]; then ok 'the file that was staged and never committed is back in tanvi/ with its content'
else bad 'deploy/alerts.yaml (staged, never committed) is not back in the working tree of tanvi/ with its content'; fi
expect_not 'no cherry-pick, merge or rebase is left in progress in tanvi/' in_progress tanvi
check_end
