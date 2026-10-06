#!/usr/bin/env bash
# Read-only verification of capstone stage 8. Exit status 0 means the Git state is as required.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/check-lib.bash"
check_begin 8 "${1:-}"
SAMPLE='classify([("billing_refund", 1.0, None)]) == "human_agent" and classify([("billing_refund", 0.8, 0.9)]) == "billing_refund"'
T='v1.3.2^{commit}'

expect 'main was not rewritten' git -C $S merge-base --is-ancestor 'v1.3.1^{commit}' main
expect 'on main a message without an embedding score is classified, not an error' py_true $S main "$SAMPLE"
expect 'the test suite passes on main' tests_pass $S main
c=$(git -C $S log --first-parent --format=%s 'v1.3.1^{commit}..main' 2>/dev/null | grep -Evc '(\(#[0-9]+\)$|^Merge pull request #[0-9]+ )')
if [ "$c" = 0 ]; then ok 'everything on main since v1.3.1 arrived through a pull request'; else bad 'main has commits since v1.3.1 that did not arrive through a pull request (../pr merge)'; fi

expect 'the tag v1.3.2 exists on the server' git -C $S rev-parse -q --verify refs/tags/v1.3.2
if [ "$(git -C $S cat-file -t refs/tags/v1.3.2 2>/dev/null)" = tag ]; then ok 'v1.3.2 is an annotated tag'; else bad 'v1.3.2 is not an annotated tag'; fi
expect 'v1.3.2 is built on v1.3.1' git -C $S merge-base --is-ancestor 'v1.3.1^{commit}' "$T"
expect 'in v1.3.2 a message without an embedding score is classified, not an error' py_true $S "$T" "$SAMPLE"
expect 'the test suite passes on v1.3.2' tests_pass $S "$T"
other=$(git -C $S diff --name-only 'v1.3.1^{commit}' "$T" 2>/dev/null | grep -Evc '^(router/classify\.py|tests/.*)$')
if git -C $S rev-parse -q --verify "$T" > /dev/null 2>&1 && [ "$other" = 0 ]; then
  ok 'v1.3.2 differs from v1.3.1 only in router/classify.py and the tests'
else
  bad 'v1.3.2 changes files other than router/classify.py and the tests, compared with v1.3.1'
fi
expect_not 'v1.3.2 contains none of the work that is on main and not released' \
  sh -c "git -C $S cat-file -e '$T:router/batch.py' || git -C $S cat-file -e '$T:router/vip.py' || git -C $S show '$T:router/scoring.py' | grep -q TENANT"
expect 'the server has the branch release/1.3' git -C $S rev-parse -q --verify refs/heads/release/1.3
expect 'release/1.3 contains v1.3.2' git -C $S merge-base --is-ancestor "$T" release/1.3
orig=$(git -C $S log --format=%B "v1.3.1^{commit}..$T" 2>/dev/null | sed -n 's/^(cherry picked from commit \([0-9a-f]\{40\}\))$/\1/p' | head -n 1)
if [ -n "$orig" ] && git -C $S merge-base --is-ancestor "$orig" main 2>/dev/null; then
  ok 'the fix in v1.3.2 names the commit on main that it was copied from'
else
  bad 'no commit in v1.3.2 says "(cherry picked from commit <ID>)" with a commit that is on main'
fi
expect_not 'no cherry-pick, merge or rebase is left in progress in you/' in_progress you
check_end
