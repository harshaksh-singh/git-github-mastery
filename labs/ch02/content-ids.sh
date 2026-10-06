#!/usr/bin/env bash
# Chapter 2, section "Content addressing": an object ID is computed from content alone, so
# the same bytes get the same ID in any repository, and even outside one.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 content-ids

snip 01-no-repository
note 'No repository here: hash-object only computes.'
run "printf 'temperature: 0.2\n' | git hash-object --stdin"
run "printf 'temperature: 0.2\n' | git hash-object --stdin"
run "printf 'temperature: 0.3\n' | git hash-object --stdin"

snip 02-two-repositories
run 'git init -q laptop'
run 'git init -q server'
run "printf 'temperature: 0.2\n' > laptop/eval.yaml"
run "printf 'temperature: 0.2\n' > server/settings.yaml"
run 'git -C laptop hash-object -w eval.yaml'
run 'git -C server hash-object -w settings.yaml'
run 'find laptop/.git/objects server/.git/objects -type f'

snip 03-trees
run 'git -C laptop add eval.yaml'
run 'git -C server add settings.yaml'
run 'git -C laptop write-tree'
run 'git -C server write-tree'
run 'mv server/settings.yaml server/eval.yaml'
run 'git -C server add -A'
run 'git -C server write-tree'

lab_end
