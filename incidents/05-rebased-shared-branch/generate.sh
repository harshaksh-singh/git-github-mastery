#!/usr/bin/env bash
# Incident 5: a developer rebases a shared branch.
# Builds server.git and the clones you/, asha/ and ravi/ of the project "feature-store".
# Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/incidents/lib/incident-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin incidents 05-rebased-shared-branch
inc_begin

inc_server
inc_clone you
cd you || exit 1
mkdir -p store
printf 'def get(entity, feature):\n    return offline.read(entity, feature)\n' > store/api.py
_c 'Add feature lookup'
printf 'ttl_seconds: 3600\n' > store/config.yaml
_c 'Add store config'
quiet 'git push -u origin main'
quiet 'git switch -c feature/online-serving'
printf 'def get_online(entity, feature):\n    return redis.hget(entity, feature)\n' > store/online.py
_c 'Add online lookup'
printf 'def get_online(entity, feature):\n    value = redis.hget(entity, feature)\n    return decode(value) if value is not None else None\n' > store/online.py
_c 'Decode online values'
quiet 'git push -u origin feature/online-serving'
cd "$LAB_DIR" || exit 1
inc_clone asha
quiet 'git -C asha switch feature/online-serving'
inc_clone ravi

# Asha adds one commit to the shared branch.
cd "$LAB_DIR/asha" || exit 1
as asha
printf 'def warm(entities, features):\n    for e in entities:\n        for f in features:\n            redis.hset(e, f, offline.read(e, f))\n' > store/warm.py
_c 'Add cache warm-up job'
quiet 'git push'

# main moves.
cd "$LAB_DIR/ravi" || exit 1
as ravi
printf 'ttl_seconds: 900\n' > store/config.yaml
_c 'Lower the TTL to 15 minutes'
quiet 'git push'

# You pull the shared branch and add two commits that you do not push yet.
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git config set pull.rebase false'
quiet 'git pull'
printf 'def get_many(entity, features):\n    return dict(zip(features, redis.hmget(entity, features)))\n' > store/batch.py
_c 'Add batched online lookup'
printf 'def get_many(entity, features):\n    values = redis.hmget(entity, features)\n    return {f: decode(v) for f, v in zip(features, values) if v is not None}\n' > store/batch.py
_c 'Decode batched values'

# Asha rebases the shared branch onto the new main and publishes it.
cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git fetch'
quiet 'git rebase origin/main'
quiet 'git push --force-with-lease'

# You pull (a merge, as configured) and push the result.
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git pull'
quiet 'git push'

inc_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Incident ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
