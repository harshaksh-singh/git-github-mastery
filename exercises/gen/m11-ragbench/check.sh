#!/usr/bin/env bash
# Read-only verification of exercise 11.11. Exit status 0 means done.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
check_begin m11-ragbench you/.git "${1:-}"
R=you
merge=$(id_of $R deploy-2026-09-11 "Merge branch 'feat/rerank'")
fmt=$(id_of $R deploy-2026-09-11 'Format the package with the new formatter')
have=$(git -C $R rev-parse -q --verify 'refs/tags/answer/culprit^{commit}' 2>/dev/null)
same 'the tag answer/culprit names the commit that changed the value' "$have" "$merge"
f=$(git -C $R show main:ragbench/retrieve.py 2>/dev/null)
expect 'TOP_K is 20 again on main' sh -c "printf '%s\n' \"\$1\" | grep -Fxq 'TOP_K = 20'" _ "$f"
expect 'the reranker constant, the tuned score and the age limit are still there' sh -c "printf '%s\n' \"\$1\" | grep -Fxq 'RERANK_TOP = 5' && printf '%s\n' \"\$1\" | grep -Fxq 'MIN_SCORE = 0.35' && printf '%s\n' \"\$1\" | grep -Fxq 'MAX_AGE_DAYS = 365'" _ "$f"
expect 'the formatting is still in place' sh -c "printf '%s\n' \"\$1\" | grep -Fq 'def retrieve(store, query):'" _ "$f"
expect 'the reranker is still on main' git -C $R cat-file -e main:ragbench/rerank.py
expect 'no published commit was rewritten (the deployed commit is an ancestor of main)' git -C $R merge-base --is-ancestor deploy-2026-09-11 main
expect 'the ignore file .git-blame-ignore-revs is committed and lists the formatter commit' sh -c "git -C $R show main:.git-blame-ignore-revs | grep -q '^$fmt'"
same 'the fix is pushed (the server has your main)' "$(git -C server.git rev-parse -q --verify refs/heads/main)" "$(git -C $R rev-parse main)"
same 'the working tree is clean' "$(git -C $R status --porcelain | wc -l | tr -d ' ')" 0
expect 'no operation is left in progress' no_operation $R
check_end
