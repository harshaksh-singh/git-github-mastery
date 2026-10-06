#!/usr/bin/env bash
# Lab 14.6 replay: take a stash entry apart. Read the stash commit, its parents and their trees,
# the ref and its reflog, take single files out of the entry, and bring everything back with
# --index. Failure: a plain "git stash pop" flattens the staged and the unstaged part into one.
# Recovery: rebuild the index from the second parent of the dropped stash commit.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14c lab-14-6-stash-anatomy
fx_14_6

snip 01-state
run 'cd evalkit'
run 'git status -s'
run 'git diff --cached --stat'
run 'git diff --stat'

snip 02-stash
run 'git stash push -u -m "wip: strip whitespace, threshold experiment"'
run 'git status -s'

snip 03-commits
run "git log --graph --format='%h [%p] %s' 'stash@{0}'"
run "git show -s --format=raw 'stash@{0}'"

snip 04-trees
note 'Staged part: first parent against second parent.'
run "git diff --name-status 'stash@{0}^1' 'stash@{0}^2'"
note 'Unstaged part: second parent against the stash commit.'
run "git diff --name-status 'stash@{0}^2' 'stash@{0}'"
note 'Untracked part: the tree of the third parent.'
run "git ls-tree --name-only 'stash@{0}^3'"

snip 05-ref
run 'cat .git/refs/stash'
run 'cat .git/logs/refs/stash'
run 'git reflog show stash'

snip 06-single-files
run "git show 'stash@{0}:config.yaml'"
run "git show 'stash@{0}^3:notes.md'"
note 'Take one file out of the entry and leave the entry where it is:'
run "git restore --source='stash@{0}' -- config.yaml"
run 'git status -s'
run 'git restore config.yaml'

snip 07-pop-index
run 'git stash pop --index'
run 'git status -s'

snip 08-failure
run 'git stash push -u -m "wip: strip whitespace, threshold experiment"'
dropped=$(git rev-parse --short 'stash@{0}')
run 'git stash pop'
run 'git status -s'
run 'git diff --cached --stat'

snip 09-recovery
note 'The second parent of the dropped stash commit still holds the index as it was:'
run "git diff --name-status HEAD '$dropped^2'"
run "git restore --staged --source='$dropped^2' -- ."
run 'git status -s'

snip 10-verification
run 'git diff --cached --stat'
run 'git diff --stat'
run 'git stash list'

lab_end
