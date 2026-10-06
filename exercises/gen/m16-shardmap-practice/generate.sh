#!/usr/bin/env bash
# Practice repositories for the Module 16 exercises 16.1 to 16.8 (the object database and its
# maintenance). Each exercise has its own directory ex-16-N/ with a piece of the project
# "shardmap" (a service that maps tenants to shards of a vector index).
# Do the exercises before you read this file: the script is the answer to several of them.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m16-shardmap-practice

seed() {
  put shardmap/assign.py <<'F'
"""Assigns a tenant to one of N shards."""

import zlib


def shard_of(tenant, shards=16):
    return zlib.crc32(tenant.encode("utf-8")) % shards
F
  put config/shards.yaml <<'F'
shards: 16
replicas: 2
F
  _c 'Add shard assignment'
  printf '# shardmap\n\nMaps tenants to index shards.\n' > README.md
  _c 'Add README'
}

# ---------------------------------------------------------------- 16.1 an object ID by hand (empty repository)
quiet 'git init ex-16-1'

# ---------------------------------------------------------------- 16.2 from a commit to file content
quiet 'git init ex-16-2'; cd ex-16-2 || exit 1
seed
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 16.3 loose objects become a pack
quiet 'git init ex-16-3'; cd ex-16-3 || exit 1
quiet 'git config set maintenance.auto false'
seed
i=1
while [ $i -le 6 ]; do
  awk -v n="$i" 'BEGIN { for (t = 0; t < 400; t++) printf "tenant-%04d: %d\n", t, (t * 7 + n * (t % 13 == 0)) % 16 }' > config/assignments.yaml
  _c "Rebalance shards, round $i"
  i=$((i + 1))
done
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 16.4 is typed by the learner
mkdir ex-16-4

# ---------------------------------------------------------------- 16.5 what gc does with unreachable objects
quiet 'git init ex-16-5'; cd ex-16-5 || exit 1
quiet 'git config set maintenance.auto false'
seed
quiet 'git switch -c spike/consistent-hashing'
printf 'def ring(tenants, shards):\n    return sorted(tenants)\n' > shardmap/ring.py
_c 'Try consistent hashing'
quiet 'git switch main'
quiet 'git branch -D spike/consistent-hashing'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 16.6 the largest blobs in history
quiet 'git init ex-16-6'; cd ex-16-6 || exit 1
seed
bin_file data/tenants.snapshot snapshot-1 90000
_c 'Add tenant snapshot for the load test'
bin_file fixtures/index.bin index-1 240000
_c 'Add index fixture'
bin_file data/tenants.snapshot snapshot-2 150000
_c 'Refresh tenant snapshot'
quiet 'git rm -q -r data fixtures'
_c 'Remove load-test data from the repository'
printf '\nLoad-test data lives in object storage.\n' >> README.md
_c 'Say where the load-test data went'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 16.7 which fsck lines matter
quiet 'git init ex-16-7'; cd ex-16-7 || exit 1
quiet 'git config set maintenance.auto false'
seed
quiet 'git switch -c spike/weights'
printf 'WEIGHTS = {"enterprise": 4}\n' > shardmap/weights.py
_c 'Try weighted tenants'
quiet 'git switch main'
quiet 'git branch -D spike/weights'
quiet 'git reflog expire --expire=now --all'
printf 'shards: 32\nreplicas: 2\n' > config/shards.yaml
quiet 'git add config/shards.yaml'
printf 'shards: 24\nreplicas: 2\n' > config/shards.yaml
_c 'Use 24 shards'
blob=$(git rev-parse HEAD~1:shardmap/assign.py)
rm -f ".git/objects/$(printf '%s' "$blob" | cut -c1-2)/$(printf '%s' "$blob" | cut -c3-)"
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 16.8 scripts that read .git by hand
quiet 'git init ex-16-8'; cd ex-16-8 || exit 1
quiet 'git config set maintenance.auto false'
seed
put tools/current-commit.sh <<'F'
#!/bin/sh
# Prints the commit that is deployed from this checkout.
cat .git/refs/heads/main
F
put tools/count-objects.sh <<'F'
#!/bin/sh
# Prints the number of objects in the repository, for the capacity dashboard.
find .git/objects -type f -path '.git/objects/??/*' | wc -l | tr -d ' '
F
chmod +x tools/*.sh
_c 'Add deployment helper scripts'
cd "$LAB_DIR" || exit 1

unset -f seed
ex_end
