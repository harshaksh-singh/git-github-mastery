#!/usr/bin/env bash
# Read-only verification of Exercise 6.9. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m06-half-merged "${1:-}"
R=hybrid-search
expect_not 'no merge is in progress any more' in_progress $R
expect_eq 'the first parent of main is the commit Ravi started from' "$(git -C $R rev-parse -q --verify 'main^1')" "$(noted ours)"
expect_eq 'the second parent of main is feature/rerank' "$(git -C $R rev-parse -q --verify 'main^2')" "$(noted theirs)"
f() { git -C $R show "main:$1" 2>/dev/null; }
expect 'retrieve() has the renamed parameter with its default and the rerank option' sh -c "git -C $R show main:search/retrieve.py | grep -Fxq 'def retrieve(query, limit=10, rerank=False):'"
expect 'the search call uses limit' sh -c "git -C $R show main:search/retrieve.py | grep -Fq 'index.search(query, limit)'"
expect 'the reranking step is there' sh -c "git -C $R show main:search/retrieve.py | grep -Fq 'reranker.sort(query, hits)'"
expect_not 'no top_k is left in retrieve.py' sh -c "git -C $R show main:search/retrieve.py | grep -q top_k"
expect_not 'configs/legacy_weights.yaml stays removed' git -C $R cat-file -e main:configs/legacy_weights.yaml
expect 'configs/weights.yaml keeps the top-level key' sh -c "git -C $R show main:configs/weights.yaml | grep -Fxq 'weights:'"
expect 'the BM25 weight of the feature (0.5) arrived in configs/weights.yaml' sh -c "git -C $R show main:configs/weights.yaml | grep -Eq '^  bm25_weight: 0\.5$'"
expect_not 'no conflict marker is committed' git -C $R grep -q -e '^<<<<<<<' -e '^=======$' -e '^>>>>>>>' main
expect 'the merge message mentions the hand-made change (weights)' sh -c "git -C $R log -1 --format=%B main | grep -qi 'weight'"
expect 'working tree and index are clean' clean_tree $R
check_end
