#!/usr/bin/env bash
# Read-only verification of exercise 16.9. Exit status 0 means done.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/gen-lib.bash"
check_begin m16-shardmap shardmap/.git "${1:-}"
R=shardmap
tmp="$EX_DIR/.check-dump.$$"
bin_file "$tmp" shards-dump 600000
blob=$(git hash-object "$tmp"); rm -f "$tmp"
expect_not 'the blob of data/shards.bin is no longer in the object database' git -C $R cat-file -e "$blob"
same 'main still ends with "Add shard configuration"' "$(git -C $R log -1 --format=%s main 2>/dev/null)" 'Add shard configuration'
same 'main still has three commits' "$(git -C $R rev-list --count main 2>/dev/null)" 3
same 'v1.0.0 is still an annotated tag on the tip of main' "$(git -C $R rev-parse -q --verify 'v1.0.0^{commit}' 2>/dev/null)" "$(git -C $R rev-parse -q --verify main 2>/dev/null)"
same 'the working tree is clean' "$(git -C $R status --porcelain | wc -l | tr -d ' ')" 0
expect 'git fsck finds no problem' git -C $R fsck --no-dangling
check_end
