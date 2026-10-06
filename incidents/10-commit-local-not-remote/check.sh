#!/usr/bin/env bash
# Read-only verification of the recovery of incident 10. Exit status 0 means recovered.
. "$(dirname "${BASH_SOURCE[0]}")/../lib/check-lib.bash"
check_begin 10-commit-local-not-remote "${1:-}"
S=server.git
for s in 'Add score aggregation' 'Add accuracy panel' 'Show p95 latency on the dashboard' 'Guard against NaN in score aggregation'; do
  n=$(git -C $S log --format=%s main 2>/dev/null | grep -Fxc "$s")
  if [ "$n" = 1 ]; then ok "main of the team repository has \"$s\" exactly once"; else bad "main of the team repository has \"$s\" $n times (expected once)"; fi
done
expect 'dashboard/aggregate.py on main filters NaN' sh -c "git -C $S show main:dashboard/aggregate.py | grep -q isnan"
expect 'dashboard/panels.py on main still shows p95 latency' sh -c "git -C $S show main:dashboard/panels.py | grep -q p95_latency_ms"
up=$(git -C ravi rev-parse --abbrev-ref 'main@{upstream}' 2>/dev/null)
if [ "$up" = upstream/main ]; then ok 'in ravi/, main follows upstream/main (the team repository)'; else bad "in ravi/, main follows ${up:-nothing} (expected upstream/main)"; fi
if [ "$(git -C ravi rev-parse -q --verify refs/heads/main)" = "$(git -C $S rev-parse main)" ]; then ok 'main in ravi/ equals main of the team repository'; else bad 'main in ravi/ differs from main of the team repository'; fi
check_end
