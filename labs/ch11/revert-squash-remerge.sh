#!/usr/bin/env bash
# Chapter 11, section 11.9: the re-merge problem belongs to merge commits, not to reverts.
# The same branch is integrated with "git merge --squash" (one ordinary commit, no second
# parent), the squash commit is reverted with a plain "git revert", the branch gets a fix,
# and a later merge brings the whole branch, because the merge base never moved.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 revert-squash-remerge

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'def score(q, d):\n    return bm25(q, d)\n' > rank.py && printf 'timeout_s: 30\n' > serve.yaml && git add . && git commit -m 'Add BM25 ranker and serving config'"
quiet 'git switch -c feature/reranker'
quiet "printf 'def rerank(q, docs):\n    return sorted(docs, key=lambda d: cross_encoder(q, d), reverse=True)\n' > rerank.py && git add rerank.py && git commit -m 'Add cross-encoder reranker'"
quiet "printf 'from rerank import rerank\n\ndef score(q, d):\n    return bm25(q, d)\n' > rank.py && git commit -am 'Call the reranker from the ranker'"
quiet 'git switch main'
quiet "printf 'recall@10: 0.71\n' > metrics.txt && git add metrics.txt && git commit -m 'Record baseline metrics'"

snip 01-squash-then-revert
run 'git merge --squash feature/reranker'
run 'git commit -m "Add cross-encoder reranker (squashed)"'
run 'git show -s --format="%h has parents: %p" HEAD'
run 'git revert --no-edit HEAD'
run 'ls'

quiet 'git switch feature/reranker'
quiet "printf 'timeout_s: 30\nrerank_top_k: 50\n' > serve.yaml && git commit -am 'Cap reranker candidates at 50'"
quiet 'git switch main'

snip 02-remerge-brings-everything
run 'git log --oneline -1 $(git merge-base main feature/reranker)'
run 'git merge feature/reranker'
run 'ls'
run 'git log --oneline --graph'

lab_end
