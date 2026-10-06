#!/usr/bin/env bash
# Lab 8.4 replay: five forms of "git restore" from one starting state, a deleted file brought
# back from the index, and "git restore -p". Failure: "git restore --source=HEAD~2 ." over the
# whole tree. Recovery: "git restore ." from the untouched index, and what it cannot bring back.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
lab_begin ch11 lab-08-4-restore-variants
fx_08_4

snip 01-start
run 'cd evalsuite'
run 'git log --oneline'
run 'git show HEAD:rubric.yaml'
run 'git show :rubric.yaml'
run 'cat rubric.yaml'
run 'git status -s'

snip 02-worktree-from-index
run 'cd ../evalsuite-1'
run 'git restore rubric.yaml'
run 'git show :rubric.yaml'
run 'cat rubric.yaml'
run 'git status -s'

snip 03-index-from-head
run 'cd ../evalsuite-2'
run 'git restore --staged rubric.yaml'
run 'git show :rubric.yaml'
run 'cat rubric.yaml'
run 'git status -s'

snip 04-both-from-head
run 'cd ../evalsuite-3'
run 'git restore --staged --worktree rubric.yaml'
run 'git show :rubric.yaml'
run 'cat rubric.yaml'
run 'git status -s'

snip 05-worktree-from-commit
run 'cd ../evalsuite-4'
run 'git restore --source=HEAD~2 rubric.yaml'
run 'git show :rubric.yaml'
run 'cat rubric.yaml'
run 'git status -s'

snip 06-both-from-commit
run 'cd ../evalsuite-5'
run 'git restore --source=HEAD~2 --staged --worktree rubric.yaml'
run 'git show :rubric.yaml'
run 'cat rubric.yaml'
run 'git status -s'
run 'git log --oneline -1'

snip 07-deleted-file
run 'rm judge.txt'
run 'git status -s'
run 'git restore judge.txt'
run 'git status -s'

snip 08-patch
run 'cd ../scorer'
run "printf 'y\nn\n' | git restore -p score.py"

snip 09-patch-result
run 'git diff'

snip 10-failure
run 'cd ../evalsuite-bulk'
run 'git status -s'
run 'git diff'
run 'git restore --source=HEAD~2 .'
run 'git status -s'
run 'ls'

snip 11-recovery
run 'git restore .'
run 'git status -s'
run 'ls'
run 'cat judge.txt'

snip 12-verification
run 'git status -s'
run 'git diff --stat HEAD'
run 'git fsck'

lab_end
