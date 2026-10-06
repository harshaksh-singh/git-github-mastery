#!/usr/bin/env bash
# A linked worktree: what "git worktree add" creates, which files are per worktree and which are
# shared. Chapter 25, sections 25.2 and 25.3.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch25 worktree-basics
fx_ragapi_feature

snip 01-add
run 'git log --graph --oneline --decorate --all'
run 'git worktree add ../rag-api-rerank feature/rerank'
run 'git worktree list'

snip 02-link-files
note 'The linked worktree has a .git FILE, not a directory:'
run 'cat ../rag-api-rerank/.git'
note 'It points at a private directory inside the one repository:'
run 'ls .git/worktrees/rag-api-rerank'
run 'cat .git/worktrees/rag-api-rerank/HEAD'
run 'cat .git/worktrees/rag-api-rerank/gitdir'
run 'cat .git/worktrees/rag-api-rerank/commondir'

snip 03-git-path
run 'cd ../rag-api-rerank'
run 'git rev-parse --git-dir'
run 'git rev-parse --git-common-dir'
note 'Per worktree:'
run 'git rev-parse --git-path HEAD --git-path index --git-path logs/HEAD --git-path ORIG_HEAD'
note 'Shared:'
run 'git rev-parse --git-path objects --git-path refs/heads/main --git-path config --git-path hooks'

snip 04-shared-objects
quiet "printf '\nTies keep their retrieval order.\n' >> docs/rerank.md"
run 'git commit -am "Document tie-breaking"'
run 'cd ../rag-api'
note 'No fetch, no push: the branch ref and the new objects are already here.'
run 'git log --oneline -2 feature/rerank'
run 'git branch -v'

snip 05-separate-state
quiet "printf '\nRelease checklist: run scripts/check.sh.\n' >> docs/deploy.md"
run 'git add docs/deploy.md'
run 'git status --short --branch'
run 'git -C ../rag-api-rerank status --short --branch'

snip 06-other-heads
note 'From any worktree you can name the HEAD of another one:'
run 'git log -1 --format="%h %s" main-worktree/HEAD'
run 'git log -1 --format="%h %s" worktrees/rag-api-rerank/HEAD'
run 'git -C ../rag-api-rerank log -1 --format="%h %s" main-worktree/HEAD'
lab_end
