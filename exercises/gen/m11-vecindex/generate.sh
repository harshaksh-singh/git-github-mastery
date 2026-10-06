#!/usr/bin/env bash
# Exercise 11.10 (Level 4): "the fix is in the release", says the log. Is it?
# Builds the project "vecindex" in vecindex/ with main, a release branch and four tags. Read
# SYMPTOMS.md, not this file, before you start: the script is the answer.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m11-vecindex

quiet 'git init vecindex'
cd vecindex || exit 1

put README.md <<'F'
# vecindex

A small in-memory vector index with brute-force search.
F
put requirements.txt <<'F'
numpy>=2.0
F
put vecindex/__init__.py <<'F'
"""vecindex: brute-force nearest neighbours."""
F
put vecindex/store.py <<'F'
"""Load and save index files."""

import numpy as np


def load(path):
    handle = open(path, "rb")
    vectors = np.load(handle)
    handle.close()
    return vectors
F
put vecindex/search.py <<'F'
"""Nearest-neighbour search."""

import numpy as np


def search(index, query, top_k=10):
    scores = index @ query
    order = np.argpartition(-scores, top_k)[:top_k]
    return order[np.argsort(-scores[order])]


def search_batch(index, queries, top_k=10):
    scores = queries @ index.T
    order = np.argpartition(-scores, top_k, axis=1)[:, :top_k]
    return [row[np.argsort(-s[row])] for row, s in zip(order, scores)]
F
_c 'Add brute-force search over a loaded index'
as asha
printf '\nSearch returns the `top_k` best rows, best first.\n' >> README.md
_c 'Document the result order'
as you
quiet "git tag -a v2.3.0 -m 'vecindex 2.3.0'"
quiet 'git branch release/2.3'

# ---- main after 2.3.0
as ravi
put vecindex/store.py <<'F'
"""Load and save index files."""

import numpy as np


def load(path):
    with open(path, "rb") as handle:
        return np.load(handle)
F
_c 'Close the index file on error'
close=$(git rev-parse HEAD)
as asha
put vecindex/search.py <<'F'
"""Nearest-neighbour search."""

import numpy as np


def search(index, query, top_k=10):
    top_k = min(top_k, len(index))
    scores = index @ query
    order = np.argpartition(-scores, top_k - 1)[:top_k]
    return order[np.argsort(-scores[order])]


def search_batch(index, queries, top_k=10):
    top_k = min(top_k, len(index))
    scores = queries @ index.T
    order = np.argpartition(-scores, top_k - 1, axis=1)[:, :top_k]
    return [row[np.argsort(-s[row])] for row, s in zip(order, scores)]
F
quiet "git add -A && git commit -m 'Clamp top_k to the index size' -m 'argpartition raises ValueError when top_k is not smaller than the number of rows. Small tenant indexes (fewer than ten documents) crashed every search and every batch search.'"
as you
put vecindex/metrics.py <<'F'
"""Search quality metrics."""


def recall_at_k(found, relevant):
    return len(set(found) & set(relevant)) / max(len(relevant), 1)
F
_c 'Add recall@k metric'
as ravi
printf '\nQuality is measured with recall@k, see `vecindex/metrics.py`.\n' >> README.md
_c 'Mention recall@k in the README'
as you
quiet "git tag -a v2.4.0 -m 'vecindex 2.4.0'"
as asha
printf 'pytest>=8\n' > requirements-dev.txt
_c 'Add development requirements'

# ---- the 2.3 maintenance line
as you
quiet 'git switch release/2.3'
printf 'numpy>=2.0,<2.3\n' > requirements.txt
_c 'Pin numpy for the 2.3 line'
quiet "git cherry-pick -x $close"
quiet "git tag -a v2.3.1 -m 'vecindex 2.3.1'"
as ravi
put vecindex/search.py <<'F'
"""Nearest-neighbour search."""

import numpy as np


def search(index, query, top_k=10):
    top_k = min(top_k, len(index))
    scores = index @ query
    order = np.argpartition(-scores, top_k - 1)[:top_k]
    return order[np.argsort(-scores[order])]


def search_batch(index, queries, top_k=10):
    scores = queries @ index.T
    order = np.argpartition(-scores, top_k, axis=1)[:, :top_k]
    return [row[np.argsort(-s[row])] for row, s in zip(order, scores)]
F
_c 'Clamp top_k to the index size'
as you
quiet 'git switch main'

ex_end vecindex
