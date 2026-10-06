#!/usr/bin/env bash
# Exercise 6.9 (Level 4): a merge that somebody else left half done.
# Builds the repository hybrid-search/ in the middle of a conflicted merge. Read SYMPTOMS.md, not
# this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m06-half-merged
ex_begin m06-half-merged

quiet 'git init hybrid-search'
cd hybrid-search || exit 1
mkdir -p search configs
printf 'def retrieve(query, top_k=5):\n    hits = index.search(query, top_k)\n    return hits\n' > search/retrieve.py
printf 'bm25_weight: 0.3\ndense_weight: 0.7\n' > configs/legacy_weights.yaml
printf '# hybrid-search\n\nCombines BM25 and dense retrieval.\n' > README.md
_c 'Add hybrid retrieval'

quiet 'git switch -c feature/rerank'
as asha
printf 'def retrieve(query, top_k=5, rerank=False):\n    hits = index.search(query, top_k)\n    if rerank:\n        hits = reranker.sort(query, hits)\n    return hits\n' > search/retrieve.py
_c 'Add optional reranking to retrieve()'
printf 'bm25_weight: 0.5\ndense_weight: 0.7\n' > configs/legacy_weights.yaml
_c 'Raise the BM25 weight to 0.5 after the offline evaluation'
ex_note theirs "$(git rev-parse HEAD)"

quiet 'git switch main'
as you
printf 'def retrieve(query, limit=10):\n    hits = index.search(query, limit)\n    return hits\n' > search/retrieve.py
_c 'Rename top_k to limit and return ten hits by default'
quiet 'git mv configs/legacy_weights.yaml configs/weights.yaml'
printf 'weights:\n  bm25_weight: 0.3\n  dense_weight: 0.7\n' > configs/weights.yaml
_c 'Replace legacy_weights.yaml by weights.yaml with a top-level key'
ex_note ours "$(git rev-parse HEAD)"

# Ravi starts the merge, sees two conflicts, and has to leave.
as ravi
quiet 'git merge feature/rerank'

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
