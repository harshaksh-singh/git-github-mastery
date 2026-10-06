#!/usr/bin/env bash
# Gate 1 (Fundamentals), hands-on part, variant B (retake): the project "shardmap".
# Builds one repository with a commit that deleted a file, a mode change Git cannot see,
# and a name that resolves to the wrong commit.
# Read SYMPTOMS.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/lib/gate-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin gates g1-b
gate_begin g1-b

quiet 'git init shardmap'
cd shardmap || exit 1
quiet "git config set user.name 'Ravi Menon' && git config set user.email ravi@example.com"
as ravi
mkdir -p shardmap scripts
printf 'import hashlib\n\ndef key_hash(key):\n    return int(hashlib.sha1(key.encode()).hexdigest(), 16)\n' > shardmap/hashing.py
printf 'from shardmap.hashing import key_hash\n\ndef shard_for(key, shards):\n    return shards[key_hash(key) %% len(shards)]\n' > shardmap/ring.py
_c 'Add hash ring'
first=$(git rev-parse HEAD)
printf '#!/bin/sh\nexec python3 -m shardmap.rebalance "$@"\n' > scripts/rebalance.sh
chmod 644 scripts/rebalance.sh
_c 'Add rebalance script'
printf '# shardmap\n\nMaps a key to a shard.\n' > README.md
_c 'Add README'
gate_note parent "$(git rev-parse HEAD)"
gate_note hashing "$(git rev-parse HEAD:shardmap/hashing.py)"

# "Unstaging" a half-done edit with git rm --cached, then committing.
printf 'import hashlib\n\ndef key_hash(key):\n    # WIP: try blake2b, half the digest\n    return int(hashlib.blake2b(key.encode(), digest_size=8).hexdigest(), 16)\n' > shardmap/hashing.py
printf 'WEIGHTS = {"shard-a": 2, "shard-b": 1, "shard-c": 1}\n' > shardmap/weights.py
quiet 'git add -A'
quiet 'git rm --cached shardmap/hashing.py'
quiet 'git commit -m "Add shard weights"'

# A mode change that Git has been told not to look at.
quiet 'git config set core.fileMode false'
chmod 755 scripts/rebalance.sh

# An attempt to "point main back", with a short name where a full ref name was needed.
quiet "git update-ref main $first"

gate_end
gate_ready
