#!/usr/bin/env bash
# Gate 2, hands-on variant B (ingestd): the model diagnosis and repair as real transcripts for
# answer-keys/gate-2-branching.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin gates solve-g2-b
gate_load gate-2-branching/variant-b
as config

snip 01-observe
run 'cd you'
run 'git status -sb'
run 'git branch -vv'
run 'git branch -r'
run 'git log --oneline --graph -4'

snip 02-anchor
note 'The two commits are reachable from HEAD only. Name them before anything else.'
run 'git switch -c feature/dedupe-window'
run 'git status -sb'

snip 03-fetch-fails
run_rc 'git fetch'
run 'git ls-remote --heads origin'
run 'git for-each-ref --format="%(refname)" refs/remotes'

snip 04-prune
run 'git remote prune --dry-run origin'
run 'git fetch --prune'
run 'git branch -r'

snip 05-upstream
run 'git branch --set-upstream-to=origin/feature/dedupe-window'
run 'git status -sb'
run 'git log --oneline --graph --left-right HEAD...@{upstream}'

snip 06-integrate
run_rc 'git push'
run 'git pull --no-rebase'
run 'git log --oneline --graph -5'
run 'git push'
run 'git status -sb'

snip 07-main
run 'git switch -q main'
run 'git merge --ff-only'
run 'git switch -q feature/dedupe-window'
run 'git branch -vv'
run 'cd ..'
show_check
gate_done
