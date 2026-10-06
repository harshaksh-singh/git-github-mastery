#!/usr/bin/env bash
# The whole life of linked worktrees: three ways to add, list formats, remove, lock, move, a working
# tree deleted by hand (prune) and one moved by hand (repair). Chapter 25, section 25.6.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch25 worktree-lifecycle
fx_ragapi_feature

snip 01-add-forms
note 'Path only: a new branch named after the last path component.'
run 'git worktree add ../spike-cache'
note 'An explicit new branch and a starting point.'
run 'git worktree add -b fix/top-k ../rag-api-fix v1.3.0'
note 'No branch at all.'
run 'git worktree add --detach ../rag-api-v1.3.0 v1.3.0'

snip 02-list
run 'git worktree list'
run 'git worktree list --porcelain | head -8'

snip 03-remove
quiet "printf 'cache: lru\n' > ../spike-cache/notes.txt"
run_rc 'git worktree remove ../spike-cache'
run 'git worktree remove --force ../spike-cache'
note 'The worktree is gone. Its branch is not:'
run 'git branch --list "spike*"'
run 'git branch -d spike-cache'

snip 04-lock
run 'git worktree lock --reason "benchmark of 1.3.0 running until Friday" ../rag-api-v1.3.0'
run 'git worktree list --verbose'
run_rc 'git worktree remove ../rag-api-v1.3.0'
run 'cat .git/worktrees/rag-api-v1.3.0/locked'
run 'git worktree unlock ../rag-api-v1.3.0'

snip 05-move
run 'git worktree move ../rag-api-v1.3.0 ../bench-1.3.0'
run 'git worktree list'

snip 06-deleted-by-hand
run 'rm -rf ../rag-api-fix'
run 'git worktree list'
run_rc 'git branch -d fix/top-k'
run 'git worktree prune --dry-run --verbose'
run 'git worktree prune --verbose'
run 'git branch -d fix/top-k'

snip 07-moved-by-hand
run 'mv ../bench-1.3.0 ../bench-old-release'
run 'git worktree list'
run 'git worktree repair ../bench-old-release'
run 'git worktree list'

snip 08-main-moved
note 'Now the main worktree itself is renamed. The linked one loses its way home:'
run 'cd .. && mv rag-api rag-api-main && cd rag-api-main'
run_rc 'git -C ../bench-old-release status --short --branch'
run 'git worktree repair'
run 'git -C ../bench-old-release status --short --branch'
lab_end
