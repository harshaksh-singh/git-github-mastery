#!/usr/bin/env bash
# Chapter 2, section "Building a commit by hand": a commit made with plumbing only.
# No git add, no git commit, and at first no file in the working tree at all.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 commit-by-hand

snip 01-blob
run 'git init handmade'
run 'cd handmade'
run "printf 'Answer only from the provided context.\n' | git hash-object -w --stdin"
blob=$(printf 'Answer only from the provided context.\n' | git hash-object --stdin)
run 'find .git/objects -type f'
run "git cat-file -t $blob"
run "git cat-file -p $blob"

snip 02-index
run "git update-index --add --cacheinfo 100644,$blob,prompts/system.txt"
run 'git ls-files --stage'
run 'git status'

snip 03-tree
run 'git write-tree'
tree=$(git write-tree)
run "git cat-file -p $tree"
subtree=$(git rev-parse "$tree:prompts")
run "git cat-file -p $subtree"
run "git ls-tree -r $tree"

snip 04-commit
run "git commit-tree $tree -m 'Add system prompt'"
commit=$(git commit-tree "$tree" -m 'Add system prompt')
run "git cat-file -p $commit"
run_rc 'git log --oneline'
run 'git fsck'

snip 05-ref
run "git update-ref refs/heads/main $commit"
run 'git log --oneline'
run 'git fsck'
run 'git status --short'

snip 06-working-tree
run 'git restore prompts/system.txt'
run 'cat prompts/system.txt'
run 'git status'

lab_end
