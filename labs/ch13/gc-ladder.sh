#!/usr/bin/env bash
# Chapter 13, section 13.13: what garbage collection does to a lost commit at each level of
# protection. With a reflog entry: nothing, even with --prune=now. Without one: "git prune -n"
# previews the deletion, "git gc" with a grace period moves the objects into a cruft pack, and
# "git gc --prune=now" deletes them. Only clock-independent cut-offs are used.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 gc-ladder
fx_searchsvc
cd searchsvc || exit 1
quiet "printf 'cache_ttl_s: 300\n' > cache.yaml && git add . && git commit -m 'Add cache TTL'"
lost=$(git rev-parse --short HEAD)
quiet 'git reset --hard HEAD~1'
cd "$LAB_DIR" || exit 1
_fx_copy searchsvc searchsvc-with-reflog
cd searchsvc-with-reflog || exit 1

snip 01-reflog-protects
run 'git reflog -2'
run 'git prune -n'
run 'git gc --prune=now'
run "git cat-file -t $lost"
run 'git count-objects -v | grep -e "^count" -e in-pack'

cd "$LAB_DIR/searchsvc" || exit 1

snip 02-preview
run 'cd ../searchsvc'
run 'git reflog expire --expire=now --all'
run 'git fsck'
run 'git prune -n'

snip 03-cruft-pack
note 'A collection that prunes nothing ("never"; the default cut-off is two weeks):'
run 'git gc --prune=never'
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'
run 'ls .git/objects/pack | cut -d. -f2 | sort | uniq -c'
run "git cat-file -t $lost"
run 'git fsck'

snip 04-prune-now
run 'git gc --prune=now'
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'
run 'ls .git/objects/pack | cut -d. -f2 | sort | uniq -c'
run_rc "git cat-file -t $lost"
run 'git fsck'

lab_end
