#!/usr/bin/env bash
# Reviewing a teammate's branch in its own worktree, without disturbing your work in progress.
# Chapter 25, section 25.5.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch25 worktree-review
fx_ragapi_review
quiet 'git switch feature/rerank'
quiet "printf '# idea: cache scores\n' >> app/rerank.py"

snip 01-fetch
run 'git status --short --branch'
run 'git fetch origin'

snip 02-detached-review
run 'git worktree add --detach ../rag-api-review origin/feature/citations'
run 'cd ../rag-api-review'
run 'git log --oneline main..HEAD'
run 'git diff --stat main...HEAD'
run 'cd ../rag-api'
run 'git worktree remove ../rag-api-review'
run 'git status --short --branch'

snip 03-with-a-branch
note 'If you intend to push commits to the branch, name it. No local branch feature/citations'
note 'exists; exactly one remote has one, so Git creates a tracking branch:'
run 'git worktree add ../rag-api-citations feature/citations'
run 'git -C ../rag-api-citations status --short --branch'
run 'git worktree list'
lab_end
