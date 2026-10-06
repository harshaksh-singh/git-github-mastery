#!/usr/bin/env bash
# The use case from the manual: an urgent fix while the main worktree is in the middle of a
# conflicted rebase. Chapter 25, section 25.5.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch25 worktree-hotfix
fx_ragapi_rebase_stopped

snip 01-stuck
run 'git status --short --branch'
run 'git branch'
run_rc 'git switch main'
run_rc 'git stash'

snip 02-add
run 'git worktree add -b hotfix/empty-question ../rag-api-hotfix main'
run 'git worktree list'

snip 03-fix
run 'cd ../rag-api-hotfix'
run 'sh scripts/check.sh'
quiet 'hotfix_edit'
run 'git diff'
run 'sh scripts/check.sh'
run 'git commit -am "Reject empty questions"'
run 'git push -u origin hotfix/empty-question'

snip 04-back
run 'cd ../rag-api'
run 'git worktree remove ../rag-api-hotfix'
run 'git worktree list'
note 'The rebase is exactly where you left it, and the hotfix branch is in the shared refs:'
run 'git status --short'
run 'git branch -vv'
lab_end
