#!/usr/bin/env bash
# Model solution of exercise 16.9 (Level 4): a blob that is unreachable from main but still
# reachable from a backup ref, a stash and the reflogs. Find every holder, then cross the point
# of no return on purpose.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m16-shardmap
ex_load m16-shardmap
cd shardmap || exit 1
COUNTS="git count-objects -v | grep -e '^count' -e in-pack -e '^packs'"

snip 01-observe
run 'git log --oneline --decorate'
run 'git ls-files'
run "$COUNTS"
run 'git log --oneline main -- data/shards.bin'

snip 02-find-the-blob
run "git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(objectname) %(rest)' | sort -k2 -n -r | head -2"
blob=$(git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(objectname) %(rest)' | sort -k2 -n -r | head -1 | cut -d' ' -f3)

snip 03-holders-refs
run 'git for-each-ref'
old=$(git log --all --format=%h --diff-filter=A -- data/shards.bin | tail -1)
run "git log --all --oneline --diff-filter=A -- data/shards.bin"
run "git for-each-ref --contains $old"

snip 04-holders-reflogs
run 'git reflog | grep -c .'
run "git reflog | grep '^${old}'"
run 'git stash list'
run 'git stash show -p stash@{0}'

snip 05-remove-refs
run 'git update-ref -d refs/backup/main-before-cleanup'
run 'git stash drop'
run 'git for-each-ref'
run 'git gc -q'
run "git cat-file -t ${blob:0:7}"

snip 06-point-of-no-return
run 'git reflog expire --expire=now --all'
run 'git gc -q --prune=now'
run_rc "git cat-file -t ${blob:0:7}"
run "$COUNTS"

snip 07-verify
run_rc 'git fsck'
run 'git log --oneline --decorate'
run 'git status -sb'
run 'cd ..'
show_check
ex_done
