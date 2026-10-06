#!/usr/bin/env bash
# Exercise 11.11 (Level 5): retrieval quality dropped after a deployment, and the evidence in the
# incident channel points at the wrong commit. Builds server.git and your clone you/ of the
# project "ragbench". Read SYMPTOMS.md, not this file, before you start: the script is the answer.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m11-ragbench

ex_server
ex_clone you
cd you || exit 1

put README.md <<'F'
# ragbench

Retrieval service for the support assistant: fetch candidates, filter by score, hand them to the generator.
F
put ragbench/__init__.py <<'F'
"""ragbench: retrieval for the support assistant."""
F
put ragbench/retrieve.py <<'F'
"""Candidate retrieval."""

# How many candidates the vector store returns, and the lowest score we keep.
TOP_K=20
MIN_SCORE=0.3


def retrieve(store,query):
    hits=store.search(query,limit=TOP_K)
    return [h for h in hits if h.score>=MIN_SCORE]
F
put ragbench/generate.py <<'F'
"""Answer generation."""

CONTEXT_DOCS=5


def build_context(hits):
    return "\n\n".join(h.text for h in hits[:CONTEXT_DOCS])
F
_c 'Add retrieval and context building'
as asha
printf '\nRetrieval returns up to `TOP_K` candidates above `MIN_SCORE`.\n' >> README.md
_c 'Document the retrieval constants'
as you
quiet 'git push -u origin main'
quiet "git tag -a deploy-2026-09-04 -m 'Deployed Friday 4 September' && git push origin deploy-2026-09-04"

# Ravi's feature branch (built in your clone: you fetched and reviewed it).
as ravi
quiet 'git switch -c feat/rerank'
put ragbench/rerank.py <<'F'
"""Cross-encoder reranking of retrieved candidates."""


def rerank(scorer,query,hits,keep):
    ranked=sorted(hits,key=lambda h:scorer(query,h.text),reverse=True)
    return ranked[:keep]
F
_c 'Add cross-encoder reranker'
put ragbench/retrieve.py <<'F'
"""Candidate retrieval."""

# How many candidates the vector store returns, and the lowest score we keep.
TOP_K=20
RERANK_TOP=5
MIN_SCORE=0.3


def retrieve(store,query):
    hits=store.search(query,limit=TOP_K)
    return [h for h in hits if h.score>=MIN_SCORE]
F
_c 'Add RERANK_TOP constant'
put ragbench/generate.py <<'F'
"""Answer generation."""

from ragbench.retrieve import RERANK_TOP


def build_context(hits):
    return "\n\n".join(h.text for h in hits[:RERANK_TOP])
F
_c 'Build the context from the reranked top'

# Meanwhile on main.
as asha
quiet 'git switch main'
put ragbench/retrieve.py <<'F'
"""Candidate retrieval."""

# How many candidates the vector store returns, and the lowest score we keep.
TOP_K=20
MIN_SCORE=0.35
MAX_AGE_DAYS=365


def retrieve(store,query):
    hits=store.search(query,limit=TOP_K)
    return [h for h in hits if h.score>=MIN_SCORE]
F
_c 'Tune retrieval constants'

# Ravi merges his branch; the constants conflict and he resolves by hand.
skip_ticks 2880
as ravi
quiet 'git merge --no-ff feat/rerank'
put ragbench/retrieve.py <<'F'
"""Candidate retrieval."""

# How many candidates the vector store returns, and the lowest score we keep.
TOP_K=5
RERANK_TOP=5
MIN_SCORE=0.35
MAX_AGE_DAYS=365


def retrieve(store,query):
    hits=store.search(query,limit=TOP_K)
    return [h for h in hits if h.score>=MIN_SCORE]
F
quiet "git add -A && git commit -m \"Merge branch 'feat/rerank'\""
quiet 'git branch -d feat/rerank'

as asha
put ragbench/retrieve.py <<'F'
"""Candidate retrieval."""

# How many candidates the vector store returns, and the lowest score we keep.
TOP_K = 5
RERANK_TOP = 5
MIN_SCORE = 0.35
MAX_AGE_DAYS = 365


def retrieve(store, query):
    hits = store.search(query, limit=TOP_K)
    return [h for h in hits if h.score >= MIN_SCORE]
F
put ragbench/generate.py <<'F'
"""Answer generation."""

from ragbench.retrieve import RERANK_TOP


def build_context(hits):
    return "\n\n".join(h.text for h in hits[:RERANK_TOP])
F
put ragbench/rerank.py <<'F'
"""Cross-encoder reranking of retrieved candidates."""


def rerank(scorer, query, hits, keep):
    ranked = sorted(hits, key=lambda h: scorer(query, h.text), reverse=True)
    return ranked[:keep]
F
_c 'Format the package with the new formatter'
as you
printf '\nCandidates are reranked before the context is built, see `ragbench/rerank.py`.\n' >> README.md
_c 'Mention reranking in the README'
quiet 'git push origin main'
quiet "git tag -a deploy-2026-09-11 -m 'Deployed Friday 11 September' && git push origin deploy-2026-09-11"

ex_end you
