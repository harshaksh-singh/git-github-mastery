#!/usr/bin/env bash
# Read-only verification of the final-test lab "debugging". Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../final-lib/check-lib.bash"
check_begin debugging "${1:-}"
R=latencylab
old=$(noted main)
expect 'HEAD is on main' on_branch $R main
expect_not 'no bisection or other operation is left in progress' in_progress $R
expect 'main still contains everything it had (nothing was rewritten)' is_ancestor $R "$old" refs/heads/main
expect 'a new commit on main says which commit it reverts, and it is the first bad one' sh -c "git -C $R log --format=%B '$old..refs/heads/main' | grep -Fq 'This reverts commit $(noted bad)'"
expect_eq 'check-p95.sh is unchanged' "$(rev $R main:check-p95.sh)" "$(noted check)"
cfg=$(git -C $R show main:config/client.yaml 2>/dev/null)
t=$(printf '%s\n' "$cfg" | sed -n 's/^timeout_ms: //p'); r=$(printf '%s\n' "$cfg" | sed -n 's/^retries: //p'); b=$(printf '%s\n' "$cfg" | sed -n 's/^backoff_ms: //p')
total=$(( ${t:-9999} * (${r:-9} + 1) + ${b:-9999} * ${r:-9} ))
if [ "$total" -le 2000 ]; then ok "the p95 check passes on main (worst case $total ms)"; else bad "the p95 check fails on main (worst case $total ms)"; fi
expect_eq 'the later commit "Raise the timeout to 450 ms" is still in effect' "$t" 450
expect 'the second region is still configured' git -C $R cat-file -e main:failover.py
expect 'nothing is staged, modified or untracked' clean_tree $R
check_end
