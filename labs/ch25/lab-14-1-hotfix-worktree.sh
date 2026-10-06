#!/usr/bin/env bash
# Lab 14.1 replay: a hotfix in a second worktree while a rebase is stopped at a conflict in the
# first. Failure scenario: the hotfix worktree is deleted with rm -rf, which leaves its branch
# "in use"; recovery with git worktree prune. Then the rebase is finished.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch25 lab-14-1-hotfix-worktree
fx_ragapi_rebase_stopped

snip 01-start
run 'git status'
run 'git worktree list'

snip 02-blocked
run_rc 'git switch main'
run_rc 'git stash'

snip 03-add
run 'git worktree add -b hotfix/empty-question ../rag-api-hotfix main'
run 'git worktree list'
run 'cat ../rag-api-hotfix/.git'

snip 04-fix
run 'cd ../rag-api-hotfix'
run 'git status --short --branch'
run 'sh scripts/check.sh'
note 'Edit app/api.py: add the two lines shown by the diff.'
quiet 'hotfix_edit'
run 'git diff'
run 'sh scripts/check.sh'
run 'git commit -am "Reject empty questions"'
run 'git push -u origin hotfix/empty-question'

snip 05-first-tree-untouched
run 'cd ../rag-api'
run 'git status --short'
run 'git log --oneline --decorate -1 hotfix/empty-question'
run 'git rev-parse --git-path rebase-merge'
run 'git -C ../rag-api-hotfix rev-parse --git-path rebase-merge'

snip 06-failure
note 'The hotfix is pushed. Tidy up the wrong way:'
run 'rm -rf ../rag-api-hotfix'
run 'git worktree list'
run_rc 'git branch -d hotfix/empty-question'
run_rc 'git worktree add ../rag-api-hotfix-2 hotfix/empty-question'

snip 07-recovery
run 'git worktree prune --dry-run --verbose'
run 'git worktree prune --verbose'
run 'git worktree list'
run 'git branch -d hotfix/empty-question'

snip 08-finish-rebase
note 'Back to the conflict. Edit app/retriever.py: keep TOP_K = 8 and the length filter from main,'
note 'and the reranking from the feature. Then:'
quiet 'resolve_retriever'
run 'git add app/retriever.py'
run 'git rebase --continue'

snip 09-verification
run 'git worktree list'
run 'git status --short --branch'
run 'git log --graph --oneline --decorate --all'
run 'ls .git/worktrees 2>&1'
lab_end
