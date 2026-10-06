#!/usr/bin/env bash
# Lab 9.4 replay: a conflict during a rebase, read through the index stages; then the classic mistake
# of resolving with --ours, which silently drops your commit, and the way back.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 lab-09-4-conflict-ours-theirs
fx_rerank_conflict

snip 01-start
run 'git log --oneline --graph --decorate --all'

snip 02-conflict
run_rc 'git rebase main'

snip 03-read
run 'git diff'
run 'git ls-files -u'

snip 04-stages
run 'git show :1:app/retriever.py | head -1'
run 'git show :2:app/retriever.py | head -1'
run 'git show :3:app/retriever.py | head -1'
run 'git log --oneline -1 HEAD'
run 'git log --oneline -1 REBASE_HEAD'

snip 05-resolve
note 'Edit app/retriever.py: keep TOP_K = 20 and delete the three marker lines.'
put app/retriever.py <<'PYEOF'
TOP_K = 20

def retrieve(query):
    return rerank(search(query, TOP_K))
PYEOF
run 'git add app/retriever.py'
run 'git rebase --continue'
run 'git log --oneline --graph --decorate --all'

snip 06-failure
run 'git reset --hard ORIG_HEAD'
run_rc 'git rebase main'
note 'You want "your" version, so you ask for ours:'
run 'git restore --ours app/retriever.py'
run 'git add app/retriever.py'
run 'git rebase --continue'

snip 07-diagnose
run 'git log --oneline main..HEAD'
run 'head -1 app/retriever.py'
run 'git range-diff main ORIG_HEAD HEAD'

snip 08-recovery
run 'git reset --hard ORIG_HEAD'
run 'git rebase -X theirs main'

snip 09-verification
run 'git log --oneline main..HEAD'
run 'head -1 app/retriever.py'
run 'git diff --stat ORIG_HEAD HEAD'
run 'git status --short --branch'
lab_end
