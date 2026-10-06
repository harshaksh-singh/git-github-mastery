#!/usr/bin/env bash
# Read-only verification of exercise 12.12. Exit status 0 means repaired.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
check_begin m12-tracehub you/.git "${1:-}"
R=you; B=feature/sampling
expect 'git fsck reports no error (exit status 0)' git -C $R fsck --no-dangling
same 'HEAD is on feature/sampling' "$(git -C $R symbolic-ref -q --short HEAD 2>/dev/null)" $B
same 'the branch has its two unpushed commits on top of main' "$(git -C $R rev-list --count main..$B 2>/dev/null)" 2
same 'the first of them is "Add per-tenant sampling rates"' "$(git -C $R log -1 --format=%s $B~1 2>/dev/null)" 'Add per-tenant sampling rates'
same 'the second is "Sample traces by tenant"' "$(git -C $R log -1 --format=%s $B 2>/dev/null)" 'Sample traces by tenant'
expect 'its sampler uses the per-tenant rate' sh -c "git -C $R show $B:tracehub/sampler.py | grep -Fq 'rate_for(trace.get(\"tenant\"))'"
expect 'the index is readable and the working tree is clean' sh -c "test -z \"\$(git -C $R status --porcelain 2>&1)\""
expect 'the oldest version of the sampler can be read again' git -C $R cat-file -p main~2:tracehub/sampler.py
same 'main is where the server has it' "$(git -C $R rev-parse -q --verify main 2>/dev/null)" "$(git -C server.git rev-parse refs/heads/main)"
ct=$(git -C $R log -1 --format=%ct $B~1 2>/dev/null)
if [ -n "$ct" ] && [ "$ct" -lt 1789965000 ]; then ok 'the first unpushed commit is the original object, not a copy made after a new clone'; else bad 'the first unpushed commit is the original object, not a copy made after a new clone'; fi
check_end
