#!/usr/bin/env bash
# Gate 2, hands-on variant A (rerank-api): the model diagnosis and repair as real transcripts
# for answer-keys/gate-2-branching.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin gates solve-g2-a
gate_load gate-2-branching/variant-a
as config

snip 01-observe
run 'cd you'
run 'git status -sb'
run 'git branch -vv'
run 'git branch -r'
run 'git ls-remote origin'

snip 02-ambiguous
run 'git switch -q main'
run 'git status -sb'
run 'git merge origin/main'
run 'git rev-parse origin/main refs/heads/origin/main refs/remotes/origin/main'
run 'git for-each-ref --format="%(refname)" "refs/*/origin/main"'

snip 03-delete-stray
note 'Would deleting the stray branch lose a commit? List what it has that the real branch lacks.'
run 'git log --oneline refs/remotes/origin/main..refs/heads/origin/main'
run 'git branch -d origin/main'
run 'git rev-parse --symbolic-full-name origin/main'
run 'git merge --ff-only origin/main'
run 'git status -sb'

snip 04-upstream
run 'git switch -q feature/mmr-rerank'
run 'git rev-parse --abbrev-ref @{upstream}'
run_rc 'git push'
run 'git push -u origin feature/mmr-rerank'
run 'git status -sb'
run 'git rev-parse --abbrev-ref @{upstream}'

snip 05-stale
run 'git remote prune --dry-run origin'
run 'git fetch --prune'
run 'git branch -vv'

snip 06-gone-is-not-merged
run 'git branch --merged origin/main'
run 'git log --oneline origin/main..spike/colbert'
run 'git log --oneline origin/main..feature/bm25-tuning'
run_rc 'git branch -d feature/bm25-tuning'
note 'The upstream is gone, so -d compares with HEAD, and HEAD is feature/mmr-rerank.'
run 'git switch -q main'
run 'git branch -d feature/bm25-tuning'
run 'git switch -q feature/mmr-rerank'
run 'git push -u origin spike/colbert'

snip 07-verify
run 'git branch -vv'
run 'git ls-remote origin'
run 'cd ..'
show_check
gate_done
