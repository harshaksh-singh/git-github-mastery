#!/usr/bin/env bash
# Chapter 9, section 9.8: rebase refuses to start on a dirty working tree; --autostash stashes the
# changes, rebases, and applies the stash again. The second half shows the stash application conflicting.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 autostash
fx_rerank_clean
git switch -q feat/rerank

snip 01-dirty
note 'An uncommitted experiment in the working tree:'
put app/rerank.py <<'PYEOF'
def rerank(docs):
    return sorted(docs, key=score, reverse=True)[:10]
PYEOF
run 'git status --short'
run_rc 'git rebase main'

snip 02-autostash
run 'git rebase --autostash main'
run 'git status --short'
run 'git stash list'

snip 03-conflict-setup
quiet 'git restore app/rerank.py'
quiet 'git switch main'
put README.md <<'MDEOF'
# ragkit

Retrieval-augmented answering service with reranking.
MDEOF
commit_all "Mention reranking in README"
quiet 'git switch feat/rerank'
note 'main gained a commit that rewrites the README sentence. You have an uncommitted edit to the same sentence.'
put README.md <<'MDEOF'
# ragkit

Retrieval-augmented answering service (internal).
MDEOF
run 'git status --short'
run 'git rebase --autostash main'

snip 04-conflict-state
run 'git status --short'
run 'git stash list'
run 'cat README.md'
run 'git log --oneline --decorate -2'

snip 05-config
run 'git config set rebase.autoStash true'
lab_end
