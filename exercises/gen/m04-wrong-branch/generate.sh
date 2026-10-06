#!/usr/bin/env bash
# Exercise 4.9 (Level 4): three commits on the wrong branch.
# Builds server.git and your clone you/ of the project "model-gateway". Read SYMPTOMS.md, not this
# file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m04-wrong-branch
ex_begin m04-wrong-branch

ex_server
ex_clone you
cd you || exit 1
mkdir -p gateway
printf 'def route(request):\n    return "small"\n' > gateway/route.py
_c 'Add request routing'
quiet 'git push -u origin main'

# An old feature that went into main long ago; its local branch was never deleted.
quiet 'git switch -c feature/old-cache'
printf 'CACHE = {}\n\ndef cached(key, compute):\n    if key not in CACHE:\n        CACHE[key] = compute()\n    return CACHE[key]\n' > gateway/cache.py
_c 'Add response cache'
quiet 'git switch main && git merge --ff-only feature/old-cache && git push'

# An experiment that is in no other branch.
quiet 'git switch -c spike/token-bucket'
printf 'class TokenBucket:\n    def __init__(self, rate):\n        self.rate = rate\n' > gateway/bucket.py
_c 'Spike: token bucket sketch'
ex_note spike "$(git rev-parse HEAD)"
quiet 'git switch main'
ex_note server_main "$(git rev-parse origin/main)"

# From here on the server refuses direct pushes to main (the part a GitHub ruleset plays).
cat > "$LAB_DIR/server.git/hooks/pre-receive" <<'HOOK'
#!/bin/sh
while read old new ref; do
  if [ "$ref" = refs/heads/main ]; then
    echo "main is protected: push a feature/<name> branch and open a pull request" >&2
    exit 1
  fi
done
HOOK
chmod +x "$LAB_DIR/server.git/hooks/pre-receive"

# The rate limiter, written on main by mistake.
printf 'LIMITS = {"default": 60}\n\ndef limit_for(tenant):\n    return LIMITS.get(tenant, LIMITS["default"])\n' > gateway/limits.py
_c 'Add per-tenant request limits'
printf 'from gateway.limits import limit_for\n\ndef route(request):\n    if request.count > limit_for(request.tenant):\n        return "rejected"\n    return "small"\n' > gateway/route.py
_c 'Reject requests above the tenant limit'
printf 'LIMITS = {"default": 60, "batch": 600}\n\ndef limit_for(tenant):\n    return LIMITS.get(tenant, LIMITS["default"])\n' > gateway/limits.py
_c 'Give the batch tenant a higher limit'
ex_note tip "$(git rev-parse HEAD)"

# Work in progress, not committed.
printf 'LIMITS = {"default": 60, "batch": 600, "internal": 6000}\n\ndef limit_for(tenant):\n    return LIMITS.get(tenant, LIMITS["default"])\n' > gateway/limits.py
ex_note wip_blob "$(git hash-object gateway/limits.py)"

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
