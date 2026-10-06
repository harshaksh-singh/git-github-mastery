#!/usr/bin/env bash
# Chapter 11, section 11.11: stash basics. push -m, list, show, show -p, apply versus pop,
# --index, -u, --staged, --keep-index and a pathspec, always from the same three-part state:
# one staged change, one unstaged change, one untracked file.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 stash-basics

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'def score(q, d):\n    return bm25(q, d)\n' > rank.py && printf 'timeout_s: 30\nretries: 2\n' > serve.yaml && git add . && git commit -m 'Add BM25 ranker and serving config'"
quiet "printf 'def score(q, d):\n    return 0.7 * bm25(q, d) + 0.3 * dense(q, d)\n' > rank.py && git add rank.py"
quiet "printf 'timeout_s: 10\nretries: 2\n' > serve.yaml"
quiet "printf 'sweep alpha from 0.5 to 0.9\n' > plan.md"

snip 01-push
run 'git status -s'
run 'git stash push -m "wip: blend dense scores"'
run 'git status -s'
run 'git stash list'

snip 02-show
run 'git stash show'
run 'git stash show -p'

snip 03-apply
run 'git stash apply -q'
run 'git status -s'
run 'git stash list'

quiet 'git restore --staged --worktree .'

snip 04-pop-index
run 'git stash pop --index'
run 'git status -s'
run 'git stash list'

snip 05-include-untracked
run 'git stash push -u -m "wip: dense blend, with the plan file"'
run 'git status -s'
run 'git stash show --include-untracked'

quiet 'git stash pop --index'

snip 06-staged-only
run 'git status -s'
run 'git stash push --staged -m "ranker change only"'
run 'git status -s'
run 'git stash show'

quiet 'git stash pop && git add rank.py'

snip 07-keep-index
run 'git status -s'
run 'git stash push --keep-index -m "everything; index left in place"'
run 'git status -s'
run 'git stash show'

quiet 'git stash pop --index'

snip 08-pathspec
run 'git status -s'
run 'git stash push -m "serving timeout only" -- serve.yaml'
run 'git status -s'
run 'git stash list'

lab_end
