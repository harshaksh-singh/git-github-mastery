#!/usr/bin/env bash
# Incident 9: a merge conflict is misunderstood.
# Builds server.git and the clones you/, asha/ and ravi/ of the project "rate-limiter".
# Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/incidents/lib/incident-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin incidents 09-misunderstood-conflict
inc_begin

# bucket <rate line> <refill argument> <token expression>: write limiter/bucket.py
bucket() {
  printf '%s\nBURST = 200\n\n\ndef allow(key, now):\n    bucket = buckets.get(key)\n    refill(bucket, now, %s)\n    return bucket.take(1)\n\n\ndef refill(bucket, now, rate):\n    bucket.tokens = %s\n    bucket.ts = now\n' "$1" "$2" "$3" > limiter/bucket.py
}
GROW='bucket.tokens + (now - bucket.ts) * rate'

inc_server
inc_clone you
cd you || exit 1
mkdir -p limiter
bucket 'RATE = 100' 'RATE' "$GROW"
_c 'Add token bucket limiter'
printf '# rate-limiter\n\nToken bucket rate limiting for the public API.\n' > README.md
_c 'Add README'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1
inc_clone asha
inc_clone ravi

# Ravi starts per-tenant limits on a branch.
cd "$LAB_DIR/ravi" || exit 1
as ravi
quiet 'git switch -c feature/per-tenant-limits'
bucket 'DEFAULT_RATE = 100' 'rate_for(key)' "$GROW"
printf 'from limiter.bucket import DEFAULT_RATE\n\ndef rate_for(key):\n    return overrides.get(key.tenant, DEFAULT_RATE)\n' > limiter/tenants.py
_c 'Look up the rate per tenant'

# Asha fixes an overload on main: two reviewed commits in the same file.
cd "$LAB_DIR/asha" || exit 1
as asha
bucket 'RATE = 100' 'RATE' "min(BURST, $GROW)"
_c 'Cap the bucket at BURST tokens'
bucket 'RATE = 50' 'RATE' "min(BURST, $GROW)"
_c 'Halve the default rate after the overload'
quiet 'git push'

# Ravi updates his branch, meets a conflict, and keeps "ours" for the whole file.
cd "$LAB_DIR/ravi" || exit 1
as ravi
quiet 'git fetch'
quiet 'git merge origin/main'
quiet 'git checkout --ours limiter/bucket.py && git add limiter/bucket.py'
quiet 'git commit --no-edit'
quiet 'git push -u origin feature/per-tenant-limits'
# The pull request is merged with a merge commit.
quiet 'git switch main && git pull'
quiet 'git merge --no-ff -m "Merge pull request #17 from feature/per-tenant-limits" feature/per-tenant-limits'
quiet 'git push'

# Work continues on main.
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git pull'
printf 'def record(key, allowed):\n    metrics.incr("limiter.allowed" if allowed else "limiter.rejected", tags=[key.tenant])\n' > limiter/metrics.py
_c 'Add limiter metrics'
quiet 'git push'

inc_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Incident ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
