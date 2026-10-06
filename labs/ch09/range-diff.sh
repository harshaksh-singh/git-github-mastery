#!/usr/bin/env bash
# Chapter 9, section 9.14: review what a rebase changed with "git range-diff". The conflict is
# resolved with a value that is neither side's, and range-diff makes that visible.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 range-diff
fx_rerank_review

snip 01-rebase
run 'git log --oneline --decorate main..feat/rerank'
quiet 'git rebase main'
note 'git rebase main stopped with a conflict in app/retriever.py: main says TOP_K = 8, your commit says 20.'
note 'You settle on 12 in the editor, then:'
put app/retriever.py <<'PYEOF'
TOP_K = 12

def retrieve(query):
    return rerank(search(query, TOP_K))
PYEOF
run 'git add app/retriever.py'
run 'git rebase --continue'

snip 02-range-diff
run 'git range-diff main ORIG_HEAD HEAD'

snip 03-other-spellings
run 'git range-diff main feat/rerank@{1} feat/rerank | head -3'
run 'git range-diff ORIG_HEAD...HEAD | head -4'

snip 04-tree-diff
run 'git diff ORIG_HEAD HEAD'
lab_end
