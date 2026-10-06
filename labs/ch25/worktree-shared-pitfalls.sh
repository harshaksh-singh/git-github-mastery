#!/usr/bin/env bash
# What is shared between worktrees although people expect it to be separate (stashes, configuration,
# hooks), what is separate although people expect it to be shared (ignored files such as a virtual
# environment), and what gc does with commits that only another worktree holds. Chapter 25, section 25.7.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch25 worktree-shared-pitfalls
fx_ragapi_feature
quiet 'mkdir -p .venv/bin && printf "#!/bin/sh\n" > .venv/bin/python'
quiet 'git worktree add ../rag-api-rerank feature/rerank'

snip 01-ignored-files
note 'The virtual environment is ignored, so it is not in any commit:'
run 'git status --short --ignored'
run 'ls -A'
run 'ls -A ../rag-api-rerank'

snip 02-stash-shared
run 'cd ../rag-api-rerank'
quiet "printf '# idea: cache scores\n' >> app/rerank.py"
run 'git stash push -m "rerank: cache idea"'
run 'cd ../rag-api'
note 'refs/stash lives under refs/, and refs/ is shared:'
run 'git stash list'
run 'git rev-parse --git-path refs/stash'

snip 03-config-shared
run 'git -C ../rag-api-rerank config set user.email rerank-bot@example.com'
run 'git config get user.email'
run 'git config list --show-origin --local | grep user.email'
quiet 'git config unset user.email'

snip 04-config-per-worktree
run_rc 'git -C ../rag-api-rerank config set --worktree user.email rerank-bot@example.com'
run 'git config set extensions.worktreeConfig true'
run 'git -C ../rag-api-rerank config set --worktree user.email rerank-bot@example.com'
run 'git -C ../rag-api-rerank config get user.email'
run 'git config get user.email'
run 'git -C ../rag-api-rerank rev-parse --git-path config.worktree'

snip 05-gc-keeps-other-worktrees
quiet 'git worktree add --detach ../rag-api-try main'
run 'cd ../rag-api-try'
quiet "printf 'TOP_K = 12\n' > app/settings.py && git add app/settings.py"
run 'git commit -m "Try twelve passages"'
run 'cd ../rag-api'
note 'That commit is on no branch. Only the HEAD of the other worktree holds it.'
run 'git branch --contains worktrees/rag-api-try/HEAD'
run 'git gc --quiet --prune=now'
run 'git cat-file -t worktrees/rag-api-try/HEAD'
lab_end
