#!/usr/bin/env bash
# Gate 2 (Branching), hands-on part, variant A: the project "rerank-api".
# Builds server.git and the clones you/ and asha/. The faults are in you/: a name that does not
# mean what it seems to mean, a branch with the wrong upstream, and stale remote-tracking refs.
# Read SYMPTOMS.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/lib/gate-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin gates g2-a
gate_begin g2-a

gate_server
gate_clone you
cd you || exit 1
mkdir -p rerank
printf 'def score(query, doc):\n    return float(len(set(query.split()) & set(doc.split())))\n' > rerank/score.py
_c 'Add overlap scorer'
printf 'from rerank.score import score\n\ndef rerank(query, docs, k=10):\n    return sorted(docs, key=lambda d: -score(query, d))[:k]\n' > rerank/api.py
_c 'Add rerank endpoint'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1

# Asha publishes two branches.
gate_clone asha
cd asha || exit 1
as asha
quiet 'git switch -c feature/bm25-tuning'
printf 'K1 = 1.2\nB = 0.75\n' > rerank/bm25.py
_c 'Add BM25 parameters'
printf 'K1 = 1.5\nB = 0.75\n' > rerank/bm25.py
_c 'Raise k1 after the offline evaluation'
quiet 'git push -u origin feature/bm25-tuning'
quiet 'git switch -c spike/colbert main'
printf 'def late_interaction(query_vecs, doc_vecs):\n    raise NotImplementedError\n' > rerank/colbert.py
_c 'Sketch late-interaction scoring'
printf 'def late_interaction(query_vecs, doc_vecs):\n    return sum(max(q @ d for d in doc_vecs) for q in query_vecs)\n' > rerank/colbert.py
_c 'Implement MaxSim'
quiet 'git push -u origin spike/colbert'
gate_note spike "$(git rev-parse spike/colbert)"

# You look at both branches, start your own work, and create a branch with an unfortunate name.
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git fetch'
quiet 'git switch feature/bm25-tuning'
quiet 'git switch spike/colbert'
quiet 'git switch -c feature/mmr-rerank origin/main'
printf 'LAMBDA = 0.7\n' > rerank/mmr.py
_c 'Add MMR trade-off parameter'
printf 'LAMBDA = 0.7\n\ndef mmr(candidates, selected, sim):\n    return max(candidates, key=lambda c: LAMBDA * c.score - (1 - LAMBDA) * max((sim(c, s) for s in selected), default=0))\n' > rerank/mmr.py
_c 'Add MMR selection'
gate_note mmr "$(git rev-parse feature/mmr-rerank)"
quiet 'git switch main'
quiet 'git branch origin/main'

# Asha merges one branch, adds a commit, and "cleans up" both branches on the server.
cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git switch main'
quiet 'git merge --no-ff -m "Merge feature/bm25-tuning" feature/bm25-tuning'
printf '# rerank-api\n\nBM25 parameters are in rerank/bm25.py.\n' > README.md
_c 'Document the BM25 parameters'
quiet 'git push origin main'
quiet 'git push origin --delete feature/bm25-tuning spike/colbert'
quiet 'git branch -D spike/colbert'
gate_note main "$(git rev-parse main)"

# You fetch, without pruning, and go back to your branch.
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git fetch'
quiet 'git switch feature/mmr-rerank'

gate_end
gate_ready
