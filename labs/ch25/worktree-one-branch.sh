#!/usr/bin/env bash
# One branch, one worktree: the refusals, the reason behind them (shown by forcing a second checkout
# of main), and the detached alternative. Chapter 25, section 25.4.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch25 worktree-one-branch
fx_ragapi_feature
quiet 'git worktree add ../rag-api-rerank feature/rerank'

snip 01-refused
run_rc 'git worktree add ../rag-api-second main'
run 'cd ../rag-api-rerank'
run_rc 'git switch main'
run 'cd ../rag-api'

snip 02-branch-protection
run_rc 'git branch -D feature/rerank'
run_rc 'git branch -f feature/rerank main'

snip 03-detached
run 'git worktree add --detach ../rag-api-readonly main'
run 'git worktree list'

snip 04-forced
note 'What the rule prevents. Force a second checkout of main:'
run 'git worktree add --force ../rag-api-dup main'
quiet "printf '\nSee docs/deploy.md for releases.\n' >> README.md"
run 'git commit -am "Point the README at the deployment notes"'
note 'Nobody touched the other worktree, and yet:'
run 'git -C ../rag-api-dup status'

snip 05-forced-explained
run 'git -C ../rag-api-dup diff --cached'

snip 06-forced-repair
note 'The branch moved under that worktree; its index and files are one commit behind.'
note 'It had no work of its own, so bring it up to date:'
run 'git -C ../rag-api-dup reset --hard'
run 'git -C ../rag-api-dup status --short --branch'
lab_end
