#!/usr/bin/env bash
# Practice repositories for the Module 13 exercises 13.1 to 13.8 (tags and versions). Each
# exercise has its own directory ex-13-N/ with a piece of the project "quotad" (a service that
# enforces per-tenant token quotas for an LLM gateway).
# Do the exercises before you read this file: the script is the answer to several of them.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m13-quotad

# step '<subject>': one more line in quota.py and a commit.
step() { printf '# %s\n' "$1" >> quota.py; _c "$1"; }
seed() {
  put quota.py <<'F'
"""Per-tenant token quotas."""

LIMITS = {"free": 20000, "team": 400000}
F
  _c 'Add quota table'
}

# ---------------------------------------------------------------- 13.1 two kinds of tag
quiet 'git init ex-13-1'; cd ex-13-1 || exit 1
seed; step 'Add daily reset'; step 'Add burst allowance'; step 'Log rejected requests'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 13.2 listing and sorting
quiet 'git init ex-13-2'; cd ex-13-2 || exit 1
seed
quiet "git tag -a v0.2.0 -m 'quotad 0.2.0'"
step 'Add daily reset'
quiet "git tag -a v0.9.0 -m 'quotad 0.9.0'"
step 'Add burst allowance'
quiet "git tag -a v0.10.0-rc.1 -m 'quotad 0.10.0, release candidate 1'"
step 'Fix burst allowance for the free tier'
quiet "git tag -a v0.10.0 -m 'quotad 0.10.0'"
step 'Log rejected requests'
quiet "git tag -a v1.0.0 -m 'quotad 1.0.0'"
step 'Add enterprise tier'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 13.3 tags and remotes
mkdir ex-13-3 && cd ex-13-3 || exit 1
ex_server; ex_clone work; cd work || exit 1
seed; step 'Add daily reset'
quiet 'git push -u origin main'
step 'Add burst allowance'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 13.4 and 13.5 describe, and what a tag name resolves to
quiet 'git init ex-13-4'; cd ex-13-4 || exit 1
seed
step 'Add daily reset'
quiet "git tag -a v1.0.0 -m 'quotad 1.0.0'"
step 'Add burst allowance'
step 'Fix burst allowance for the free tier'
quiet 'git tag staging-ok'
step 'Log rejected requests'
step 'Add enterprise tier'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 13.6 a patch release from a release branch
quiet 'git init ex-13-6'; cd ex-13-6 || exit 1
seed
quiet "git tag -a v1.0.0 -m 'quotad 1.0.0'"
step 'Add burst allowance'
printf 'def refund(used, tokens):\n    return max(used - tokens, 0)\n' > refund.py
_c 'Fix negative usage after a refund'
step 'Add enterprise tier'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 13.7 the version that will not move
mkdir ex-13-7 && cd ex-13-7 || exit 1
ex_server; ex_clone dev; cd dev || exit 1
seed
put scripts/version.sh <<'F'
#!/bin/sh
# Prints the version that the service reports on /version.
git describe
F
chmod +x scripts/version.sh
_c 'Add version script'
quiet "git tag -a v1.0.0 -m 'quotad 1.0.0'"
step 'Add daily reset'; step 'Add burst allowance'; step 'Log rejected requests'
quiet 'git tag v1.1.0'                                   # the release script forgot -a
step 'Add enterprise tier'
quiet 'git push -u origin main && git push origin v1.0.0 v1.1.0'
cd .. || exit 1
ex_clone ci
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 13.8 one name, two refs
mkdir ex-13-8 && cd ex-13-8 || exit 1
ex_server; ex_clone work; cd work || exit 1
seed; step 'Add daily reset'
quiet "git tag -a v1.0 -m 'quotad 1.0'"
step 'Add burst allowance'
quiet 'git push -u origin main && git push origin v1.0'
quiet 'git switch -c v1.0 v1.0'                          # a maintenance branch named like the tag
printf 'def refund(used, tokens):\n    return max(used - tokens, 0)\n' > refund.py
_c 'Fix negative usage after a refund'
quiet 'git switch main'
cd "$LAB_DIR" || exit 1

unset -f step seed
ex_end
