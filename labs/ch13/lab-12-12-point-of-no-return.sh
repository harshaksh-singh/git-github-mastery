#!/usr/bin/env bash
# Lab 12.12 replay: a commit that only the reflog protects is taken past the point of no
# return in two steps: "git reflog expire --expire=now --all", then "git gc --prune=now".
# Every recovery tool is tried and fails. Failure: a reachable object is deleted, which is
# corruption. Recovery: both losses are repaired from copies outside the repository, a
# teammate's clone and a bundle.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 lab-12-12-point-of-no-return
fx_12_12
lost=$(git -C featurestore rev-parse --short 'HEAD@{1}')

snip 01-level-reflog
run 'cd featurestore'
run 'git log --oneline'
run 'git reflog -2'
run "git cat-file -t $lost"
run 'git fsck'

snip 02-expire
run 'git reflog expire --expire=now --all'
run 'git reflog'
run 'git fsck'
run "git log --oneline -1 $lost"
run 'git count-objects -v | grep -e "^count" -e in-pack'

snip 03-prune
run 'git gc --prune=now'
run 'git count-objects -v | grep -e "^count" -e in-pack'
run_rc "git cat-file -t $lost"

snip 04-proof
run 'git reflog'
run 'git fsck --lost-found'
run 'cat .git/ORIG_HEAD'
run_rc 'git cat-file -t ORIG_HEAD'
run_rc "git branch rescue/ttl $lost"

snip 05-failure
run 'cd ../featurestore-damaged'
run 'git rev-parse HEAD:store.py'
run "rm -f .git/objects/\$(git rev-parse HEAD:store.py | sed 's/../&\//')"
run 'git status -sb'
run_rc 'git show HEAD:store.py'
run_rc 'git fsck --name-objects'

snip 06-recovery-object
run_rc 'git fetch ../teammate main'
run_rc 'git fsck'
run 'git rev-parse HEAD:store.py | git -C ../teammate pack-objects --stdout -q | git unpack-objects -q'
run_rc 'git fsck'
run 'git show HEAD:store.py'

snip 07-recovery-bundle
run 'cd ../featurestore'
run 'git bundle verify ../featurestore-backup.bundle'
run 'git fetch ../featurestore-backup.bundle main:rescue/ttl'
run 'git log --oneline rescue/ttl'
run "git cat-file -t $lost"

snip 08-verification
run 'git fsck'
run 'git diff --stat main rescue/ttl'
run 'git merge --ff-only rescue/ttl'
run 'git log --oneline'

lab_end
