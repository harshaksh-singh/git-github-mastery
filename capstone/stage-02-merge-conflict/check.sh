#!/usr/bin/env bash
# Read-only verification of capstone stage 2. Exit status 0 means the Git state is as required.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/check-lib.bash"
check_begin 2 "${1:-}"
B=feature/low-confidence-penalty

expect 'main on the server still contains v1.3.1 (history was not rewritten)' git -C $S merge-base --is-ancestor 'v1.3.1^{commit}' main
once 'the per-tenant weights are on main, once' $S main 'Add per-tenant embedding weights (#13)'
n=$(pr_of $B)
if [ "$(pr_state "$n")" = merged ]; then ok "pull request #$n ($B) is merged"; else bad "pull request #$n ($B) is not merged"; fi
expect 'the test suite passes on main' tests_pass $S main
expect 'the test of the per-tenant weight is on main' sh -c "git -C $S grep -q 'def test_tenant_weight_overrides_the_default' main -- tests"
expect 'the test of the disagreement penalty is on main' sh -c "git -C $S grep -q 'def test_disagreement_halves_the_score' main -- tests"
expect 'tests/test_scoring.py has more tests on main than in v1.3.1 (no test was dropped in a merge)' sh -c "[ \"\$(git -C $S grep -c 'def test_' 'v1.3.1^{commit}' -- tests/test_scoring.py | cut -d: -f3)\" -lt \"\$(git -C $S grep -c 'def test_' main -- tests/test_scoring.py | cut -d: -f3)\" ]"
expect 'on main a tenant with its own weight gets that weight' \
  py_true $S main 'abs(blend(0.0, 0.5, "acme-retail") - 0.3) < 1e-9 and abs(blend(0.0, 0.5) - 0.4) < 1e-9'
expect 'on main the score is halved when the two signals disagree' \
  py_true $S main 'abs(blend(1.0, 0.0) - 0.1) < 1e-9 and abs(blend(0.9, 0.5) - 0.58) < 1e-9'
expect 'on main both rules hold together for a tenant with its own weight' \
  py_true $S main 'abs(blend(1.0, 0.0, "acme-retail") - 0.2) < 1e-9'
expect 'classify passes the tenant on to the blend' \
  py_true $S main 'classify([("a", 0.4, 0.6)]) == "a" and classify([("a", 0.4, 0.6)], "acme-retail") == "human_agent"'
n=$(git -C $S log --first-parent --format=%s 'v1.3.1^{commit}..main' 2>/dev/null | grep -Evc '(\(#[0-9]+\)$|^Merge pull request #[0-9]+ )')
if [ "$n" = 0 ]; then ok 'everything on main since v1.3.1 arrived through a pull request'; else bad 'main has commits since v1.3.1 that did not arrive through a pull request (../pr merge)'; fi
expect_not 'no merge, cherry-pick or rebase is left in progress in you/' in_progress you
check_end
