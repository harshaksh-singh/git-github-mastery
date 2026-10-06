#!/usr/bin/env bash
# Chapter 2, section "The commit graph": parents, a merge commit with two parents,
# reachability, and a commit that exists but that no ref can reach.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 graph

quiet 'git init pipeline'
cd pipeline || exit 1
quiet "printf 'load\n' > steps.txt && git add steps.txt && git commit -m 'Add load step'"
quiet "printf 'load\nclean\n' > steps.txt && git commit -am 'Add clean step'"
quiet 'git switch -c feature/dedupe'
quiet "printf 'drop exact duplicates\n' > dedupe.txt && git add dedupe.txt && git commit -m 'Add dedupe rules'"
quiet 'git switch main'
quiet "printf 'load\nclean\nsplit\n' > steps.txt && git commit -am 'Add split step'"
quiet 'git merge --no-edit feature/dedupe'

snip 01-graph
run 'git log --graph --decorate --oneline --all'

snip 02-parents
run "git log --format='%h  parents: %p' main"
run 'git cat-file -p main'

snip 03-reachable
run 'git rev-list --count main'
run 'git rev-list --count feature/dedupe'
run 'git log --oneline feature/dedupe'
run_rc 'git merge-base --is-ancestor feature/dedupe main'
run_rc 'git merge-base --is-ancestor main feature/dedupe'

snip 04-unreachable
run "git commit-tree 'main^{tree}' -p main -m 'Experiment that no ref points at'"
orphan=$(git commit-tree 'main^{tree}' -p main -m 'Experiment that no ref points at')
run "git cat-file -t $orphan"
run 'git rev-list --count --all'
run 'git fsck'

snip 05-rescued
run "git branch rescue $orphan"
run 'git rev-list --count --all'
run 'git fsck'
run 'git log --graph --decorate --oneline --all'

lab_end
