#!/usr/bin/env bash
# Lab 1.1: build two commits by hand with plumbing commands, prove that git add and git commit
# build the same tree, then lose a third commit on purpose and get it back. The content is the
# same as in the first repository of Chapter 1, so the blob and tree IDs must come out identical
# to the ones git add and git commit made there.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 lab-01-1-commit-by-hand

snip 01-blobs
run 'git init handmade'
run 'cd handmade'
run "printf '# rag-eval\n' | git hash-object -w --stdin"
readme=$(printf '# rag-eval\n' | git hash-object --stdin)
run "printf 'model: small-v2\ntimeout_s: 60\n' | git hash-object -w --stdin"
config=$(printf 'model: small-v2\ntimeout_s: 60\n' | git hash-object --stdin)
run "git cat-file -t $readme"
run "git cat-file -p $config"

snip 02-index
run "git update-index --add --cacheinfo 100644,$readme,README.md"
run "git update-index --add --cacheinfo 100644,$config,configs/eval.yaml"
run 'git ls-files --stage'

snip 03-tree
run 'git write-tree'
tree1=$(git write-tree)
run "git cat-file -p $tree1"
run "git ls-tree -r $tree1"

snip 04-commit
run "git commit-tree $tree1 -m 'Add README and evaluation config'"
c1=$(git commit-tree "$tree1" -m 'Add README and evaluation config')
run "git cat-file -p $c1"
run "git update-ref refs/heads/main $c1"
run 'git log --oneline'

snip 05-second-commit
run "printf 'model: small-v2\ntimeout_s: 60\ntop_k: 5\n' | git hash-object -w --stdin"
config2=$(printf 'model: small-v2\ntimeout_s: 60\ntop_k: 5\n' | git hash-object --stdin)
run "git update-index --cacheinfo 100644,$config2,configs/eval.yaml"
run 'git write-tree'
tree2=$(git write-tree)
run "git commit-tree $tree2 -p $c1 -m 'Add top_k to evaluation config'"
c2=$(git commit-tree "$tree2" -p "$c1" -m 'Add top_k to evaluation config')
run "git update-ref refs/heads/main $c2 $c1"
run 'git log --oneline'
run "git cat-file -p $c2"

snip 06-working-tree
run 'git status --short'
run 'git restore .'
run 'git status'
run 'cat configs/eval.yaml'

snip 07-checkpoint
note 'Checkpoint: the same two files through git add and git commit, in a second repository.'
run 'git init -q ../porcelain'
run 'mkdir ../porcelain/configs'
run "printf '# rag-eval\n' > ../porcelain/README.md"
run "printf 'model: small-v2\ntimeout_s: 60\ntop_k: 5\n' > ../porcelain/configs/eval.yaml"
run 'git -C ../porcelain add .'
run 'git -C ../porcelain commit -q -m "Add README and evaluation config with top_k"'
run "git -C ../porcelain rev-parse 'HEAD^{tree}'"
run "git rev-parse 'main^{tree}'"

snip 08-lost-commit
note 'Failure scenario: make a third commit and forget to move the branch.'
run "printf '# rag-eval\n\nEvaluation harness for the retrieval service.\n' > README.md"
run 'git hash-object -w README.md'
readme2=$(git hash-object README.md)
run "git update-index --cacheinfo 100644,$readme2,README.md"
run 'git write-tree'
tree3=$(git write-tree)
run "git commit-tree $tree3 -p $c2 -m 'Describe the project in the README'"
c3=$(git commit-tree "$tree3" -p "$c2" -m 'Describe the project in the README')
run 'git log --oneline'
run 'git status'

snip 09-find-it
run 'git fsck'
run "git cat-file -p $c3"

snip 10-refused
note 'Three more mistakes. Git refuses each of them, and nothing changes.'
run_rc "git update-index --cacheinfo 100644,$readme,docs/intro.md"
run_rc "git update-ref refs/heads/main $readme"
run_rc "git update-ref refs/heads/main $c3 $c1"

snip 11-recover
note 'Recovery: move the branch, and state the value you expect it to have now.'
run "git update-ref -m 'by hand: describe the project' refs/heads/main $c3 $c2"

snip 12-verify
run 'git log --oneline'
run 'git fsck'
run 'git status'
run 'git reflog show main'

lab_end
