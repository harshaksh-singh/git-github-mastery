#!/usr/bin/env bash
# Partial staging with "git add -p": one file, three unrelated changes, two commits,
# and one change that must never be committed. Chapter 5, section 5.5.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/keys.inc"
lab_begin ch05 add-patch

git init -q support-bot
cd support-bot || exit 1
mkdir -p src
cat > src/retriever.py <<'PY'
"""Retrieval for the support bot."""
import math

TOP_K = 5
MIN_SCORE = 0.2


def normalize(vec):
    length = math.sqrt(sum(x * x for x in vec))
    return [x / length for x in vec]


def score(query_vec, doc_vec):
    return sum(q * d for q, d in zip(query_vec, doc_vec))


def retrieve(query_vec, index):
    query_vec = normalize(query_vec)
    scored = [(score(query_vec, vec), doc_id) for doc_id, vec in index]
    scored.sort(reverse=True)
    return [(s, doc_id) for s, doc_id in scored[:TOP_K] if s >= MIN_SCORE]
PY
quiet 'git add . && git commit -m "Add retriever"'

# Three unrelated edits in the working tree.
cat > src/retriever.py <<'PY'
"""Retrieval for the support bot."""
import math

TOP_K = 8
MIN_SCORE = 0.2


def normalize(vec):
    length = math.sqrt(sum(x * x for x in vec))
    if length == 0:
        return vec
    return [x / length for x in vec]


def score(query_vec, doc_vec):
    return sum(q * d for q, d in zip(query_vec, doc_vec))


def retrieve(query_vec, index):
    query_vec = normalize(query_vec)
    scored = [(score(query_vec, vec), doc_id) for doc_id, vec in index]
    scored.sort(reverse=True)
    print("DEBUG scored:", scored)
    return [(s, doc_id) for s, doc_id in scored[:TOP_K] if s >= MIN_SCORE]
PY

snip 01-the-diff
run 'git diff --stat'
run 'git diff'

snip 02-help
note 'Answer "?" to see what each letter does, then "q" to leave without staging anything.'
run_keys '? q' 'git add -p'

snip 03-split-and-choose
note 'Answers: s (split), n (TOP_K: not in this commit), y (the fix), n (the debug print).'
run_keys 's n y n' 'git add -p'

snip 04-result
run 'git status --short'
run 'git diff --cached'

snip 05-export-the-proposed-commit
note 'The staged snapshot has never existed as files. Export it to test it.'
run 'git checkout-index --all --prefix=../staged-snapshot/'
run 'diff ../staged-snapshot/src/retriever.py src/retriever.py'

snip 06-commit-and-continue
run 'git commit -m "Return zero vectors unchanged from normalize"'
note 'Second pass: y (TOP_K), n (the debug print).'
run_keys 'y n' 'git add -p'
run 'git commit -m "Raise TOP_K to 8"'
run 'git diff'

lab_end
