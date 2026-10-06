#!/usr/bin/env bash
# Chapter 11, section 11.9: the second way out of a reverted merge. Instead of reverting the
# revert, the branch is recreated with new commits ("git rebase --no-ff" from the point where
# the branch started), and then merges normally. The demo first shows the common mistake:
# a plain "git rebase main" replays only the commits that main does not have yet, so the
# reverted work is silently left out.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 revert-merge-rebuild

# Same history as the revert-merge demo: merge, revert of the merge, one fix on the branch.
quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'def score(q, d):\n    return bm25(q, d)\n' > rank.py && printf 'timeout_s: 30\n' > serve.yaml && git add . && git commit -m 'Add BM25 ranker and serving config'"
quiet 'git switch -c feature/reranker'
quiet "printf 'def rerank(q, docs):\n    return sorted(docs, key=lambda d: cross_encoder(q, d), reverse=True)\n' > rerank.py && git add rerank.py && git commit -m 'Add cross-encoder reranker'"
quiet "printf 'from rerank import rerank\n\ndef score(q, d):\n    return bm25(q, d)\n' > rank.py && git commit -am 'Call the reranker from the ranker'"
quiet 'git switch main'
quiet "printf 'recall@10: 0.71\n' > metrics.txt && git add metrics.txt && git commit -m 'Record baseline metrics'"
quiet 'git merge feature/reranker'
merge_commit=$(git rev-parse --short HEAD)
quiet 'git revert --no-edit -m 1 HEAD'
quiet 'git switch feature/reranker'
quiet "printf 'timeout_s: 30\nrerank_top_k: 50\n' > serve.yaml && git commit -am 'Cap reranker candidates at 50'"
quiet 'git switch main'

cd "$LAB_DIR" || exit 1
cp -R ranker ranker-naive
git -C ranker-naive status > /dev/null 2>&1

cd "$LAB_DIR/ranker-naive" || exit 1
snip 01-plain-rebase-leaves-the-work-out
run 'git log --oneline --graph --all'
run 'git rebase main feature/reranker'
run 'git log --oneline main..feature/reranker'
run 'ls'

cd "$LAB_DIR/ranker" || exit 1
snip 02-recreate-the-branch
note "Where the branch started: the merge base of the two parents of the reverted merge."
run "git merge-base $merge_commit^1 $merge_commit^2"
fork=$(git merge-base "$merge_commit^1" "$merge_commit^2")
fork=$(git rev-parse --short "$fork")
run "git rebase --no-ff $fork feature/reranker"
run 'git log --oneline --graph --all'

snip 03-merge-brings-everything
run 'git switch main'
run 'git merge feature/reranker'
run 'ls'
run 'cat rank.py'

lab_end
