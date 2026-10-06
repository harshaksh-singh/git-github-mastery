#!/usr/bin/env bash
# git lfs migrate: info, import (a history rewrite of the unpushed commits), what it leaves in the
# working tree and in the object database. Chapter 22, section 22.9.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch22 lfs-migrate
fx_transcriber_plain

snip 01-info
run 'git status --short --branch'
run 'git lfs migrate info'
run 'git lfs migrate info --above=1mb'

snip 02-import
run 'git log --oneline'
run 'git lfs install --local'
run 'git lfs migrate import --include="*.onnx"'
run 'git log --oneline'

snip 03-what-changed
run 'git show --stat --format="%h %s" HEAD~3'
run 'cat .gitattributes'
run 'git rev-list --objects main | git cat-file --batch-check="%(objecttype) %(objectsize) %(rest)" | grep onnx'
run 'git lfs migrate info'

snip 04-working-tree
run 'wc -c models/acoustic.onnx'
run 'git lfs ls-files'
run 'git lfs checkout'
run 'wc -c models/acoustic.onnx'
run 'git lfs ls-files'
run 'git status --short --branch'

snip 05-old-objects
note 'The old commits are no longer on any branch, but the reflog still holds them:'
run 'git reflog -2'
run 'git cat-file --batch-all-objects --batch-check="%(objecttype) %(objectsize)" | grep -c -E "blob [0-9]{7}"'
run 'git reflog expire --expire=now --all'
run 'git gc --quiet --prune=now'
run 'git cat-file --batch-all-objects --batch-check="%(objecttype) %(objectsize)" | grep -c -E "blob [0-9]{7}"'
run 'find .git/lfs/objects -type f | sort'

lab_end
