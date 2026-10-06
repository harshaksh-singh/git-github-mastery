#!/usr/bin/env bash
# Chapter 11, section 11.4: ORIG_HEAD is a single slot. A merge writes it, and so does the
# reset that "git stash push" runs internally, so a stash taken after a merge silently
# replaces the value you were about to use. The reflog still has the full sequence.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 orig-head-slot

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'def score(q, d):\n    return bm25(q, d)\n' > rank.py && printf 'recall@10: 0.71\n' > metrics.txt && git add . && git commit -m 'Add BM25 ranker and baseline metrics'"
quiet 'git switch -c feature/reranker'
quiet "printf 'def rerank(q, docs):\n    return sorted(docs, key=lambda d: cross_encoder(q, d), reverse=True)\n' > rerank.py && git add rerank.py && git commit -m 'Add cross-encoder reranker'"
quiet 'git switch main'
quiet "printf 'timeout_s: 30\n' > serve.yaml && git add serve.yaml && git commit -m 'Add serving config'"
quiet "printf 'recall@10: 0.74\n' > metrics.txt"

snip 01-merge-then-stash
run 'git merge feature/reranker'
run 'git log --oneline -1 ORIG_HEAD'
run 'git stash push -m "wip: new recall numbers"'
run 'git log --oneline -1 ORIG_HEAD'

snip 02-reflog-has-it
run 'git reflog -3'
run 'git reset --hard HEAD@{2}'
run 'git log --oneline'
run 'git stash pop -q'
run 'git status -s'

lab_end
