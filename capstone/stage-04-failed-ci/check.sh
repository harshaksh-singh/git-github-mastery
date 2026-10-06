#!/usr/bin/env bash
# Read-only verification of capstone stage 4. Exit status 0 means the Git state is as required.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/check-lib.bash"
check_begin 4 "${1:-}"
B=feature/batch-endpoint

expect 'main was not rewritten' git -C $S merge-base --is-ancestor 'v1.3.1^{commit}' main
n=$(pr_of $B)
if [ "$(pr_state "$n")" = merged ]; then ok "pull request #$n ($B) is merged"; else bad "pull request #$n ($B) is not merged"; fi
expect 'router/batch.py is on main' git -C $S cat-file -e main:router/batch.py
expect 'the test of the batch entry point is on main' sh -c "git -C $S grep -q 'def test_batch_counts_fallbacks' main -- tests"
expect 'the test suite passes on main' tests_pass $S main
expect 'the change that was merged before this pull request is still on main, unchanged in behavior' \
  py_true $S main 'fallback_for("acme-retail") == "store_support" and fallback_for() == "human_agent"'
expect 'on main a batch reports the intents and counts the fallbacks' \
  py_true $S main '__import__("router.batch", fromlist=["classify_batch"]).classify_batch([[("billing_refund", 0.8, 0.9)], [("order_status", 0.1, 0.2)]]) == (["billing_refund", "human_agent"], 1)'
expect 'on main a batch counts the fallbacks of a tenant correctly as well' \
  py_true $S main '__import__("router.batch", fromlist=["classify_batch"]).classify_batch([[("order_status", 0.1, 0.2)]], "acme-retail") == (["store_support"], 1)'
c=$(git -C $S log --first-parent --format=%s 'v1.3.1^{commit}..main' 2>/dev/null | grep -Evc '(\(#[0-9]+\)$|^Merge pull request #[0-9]+ )')
if [ "$c" = 0 ]; then ok 'everything on main since v1.3.1 arrived through a pull request'; else bad 'main has commits since v1.3.1 that did not arrive through a pull request (../pr merge)'; fi
for p in you tanvi; do expect_not "no merge or rebase is left in progress in $p/" in_progress $p; done
check_end
