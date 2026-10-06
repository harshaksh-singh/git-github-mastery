#!/usr/bin/env bash
# Exercise 16.9 (Level 4): a large file was "removed from history", and the repository is as big
# as before. Builds the project "shardmap" in shardmap/. Read SYMPTOMS.md, not this file: the
# script is the answer to "what still holds the file".
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m16-shardmap

quiet 'git init shardmap'
cd shardmap || exit 1
quiet 'git config set maintenance.auto false'
put shardmap/assign.py <<'F'
"""Assigns a tenant to one of N shards."""

import zlib


def shard_of(tenant, shards=16):
    return zlib.crc32(tenant.encode("utf-8")) % shards
F
_c 'Add shard assignment'
bin_file data/shards.bin shards-dump 600000
_c 'Add shard dump for debugging'
printf '# shardmap\n\nMaps tenants to index shards.\n' > README.md
_c 'Add README'
printf 'shards: 16\nreplicas: 2\n' > shards.yaml
_c 'Add shard configuration'

# Work in progress on the old history, put aside.
printf 'shards: 32\nreplicas: 2\n' > shards.yaml
quiet "git stash push -m 'try 32 shards'"

# The cleanup: main is rebuilt without the commit that added the dump (the two later commits
# are replayed on its parent), with a backup ref as a precaution. Done in a throwaway branch.
quiet 'git update-ref refs/backup/main-before-cleanup main'
quiet 'git switch -c cleanup main~3'
quiet 'git cherry-pick main~1 main'
quiet 'git branch -f main cleanup'
quiet 'git switch main'
quiet 'git branch -D cleanup'
quiet "git tag -a v1.0.0 -m 'shardmap 1.0.0'"
quiet 'git gc'

ex_end shardmap
