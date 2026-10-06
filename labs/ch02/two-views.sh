#!/usr/bin/env bash
# Chapter 2, section "Holding both views": a cherry-pick produces a commit whose snapshot
# differs from the original and whose change is identical.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 two-views

quiet 'git init service'
cd service || exit 1
quiet "printf 'retries: 1\n' > client.yaml && printf 'workers: 2\n' > server.yaml && git add . && git commit -m 'Add client and server settings'"
quiet 'git branch release/1.0'
quiet "printf 'workers: 4\n' > server.yaml && git commit -am 'Run four workers'"
quiet "printf 'retries: 3\n' > client.yaml && git commit -am 'Retry failed calls three times'"

snip 01-before
run 'git log --graph --decorate --oneline --all'
run 'git show --stat --format="%h %s" main'

snip 02-cherry-pick
run 'git switch release/1.0'
run 'git cherry-pick main'
run 'git log --graph --decorate --oneline --all'

snip 03-snapshots-differ
run 'git ls-tree main'
run 'git ls-tree release/1.0'

snip 04-change-is-the-same
run 'git show --stat --format="%h %s" release/1.0'
run 'git show main | git patch-id --stable'
run 'git show release/1.0 | git patch-id --stable'

lab_end
