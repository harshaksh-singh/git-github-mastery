#!/usr/bin/env bash
# Chapter 11, section 11.9: reverting a merge with "-m 1", and the re-merge problem.
# After the revert, merging the same branch again brings nothing; after a fix is added to the
# branch, a merge brings only the fix and silently leaves out the original work. The cure is
# to revert the revert first.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 revert-merge

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'def score(q, d):\n    return bm25(q, d)\n' > rank.py && printf 'timeout_s: 30\n' > serve.yaml && git add . && git commit -m 'Add BM25 ranker and serving config'"
quiet 'git switch -c feature/reranker'
quiet "printf 'def rerank(q, docs):\n    return sorted(docs, key=lambda d: cross_encoder(q, d), reverse=True)\n' > rerank.py && git add rerank.py && git commit -m 'Add cross-encoder reranker'"
quiet "printf 'from rerank import rerank\n\ndef score(q, d):\n    return bm25(q, d)\n' > rank.py && git commit -am 'Call the reranker from the ranker'"
quiet 'git switch main'
quiet "printf 'recall@10: 0.71\n' > metrics.txt && git add metrics.txt && git commit -m 'Record baseline metrics'"

snip 01-merge
run 'git merge feature/reranker'
run 'git log --oneline --graph'
run 'ls'

snip 02-revert-needs-m
run_rc 'git revert --no-edit HEAD'
run 'git show -s --format="%h has parents: %p" HEAD'
run 'git revert --no-edit -m 1 HEAD'
run 'ls'
revert_commit=$(git rev-parse --short HEAD)

snip 03-revert-message
run 'git show -s --format=%B HEAD'
run 'git log --oneline --graph -3'

snip 04-remerge-brings-nothing
run 'git merge feature/reranker'
run 'git merge-base main feature/reranker'
run 'git rev-parse feature/reranker'

# The team fixes the problem on the branch: one new commit, in a file the branch had not touched.
quiet 'git switch feature/reranker'
quiet "printf 'timeout_s: 30\nrerank_top_k: 50\n' > serve.yaml && git commit -am 'Cap reranker candidates at 50'"
quiet 'git switch main'

snip 05-remerge-brings-only-the-fix
run 'git log --oneline main..feature/reranker'
run 'git merge feature/reranker'
run 'ls'
run 'cat serve.yaml'
run 'cat rank.py'

snip 06-revert-the-revert
run 'git reset --hard ORIG_HEAD'
run "git revert --no-edit $revert_commit"
run 'git merge feature/reranker'
run 'ls'

snip 07-final-graph
run 'git log --oneline --graph'
run 'cat rank.py'

lab_end
