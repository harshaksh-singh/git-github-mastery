#!/usr/bin/env bash
# Read-only verification of capstone stage 1. Exit status 0 means the Git state is as required.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/check-lib.bash"
check_begin 1 "${1:-}"
SAMPLE='classify([("billing_refund", keyword_score(12), 0.10)]) == "human_agent"'

expect 'main on the server still contains the release v1.3.0 (history was not rewritten)' \
  git -C $S merge-base --is-ancestor v1.3.0 main
expect 'the keyword-stuffed sample message goes to a human agent again on main' py_true $S main "$SAMPLE"
expect 'the test suite passes on main' tests_pass $S main

culprit=$(git -C $S log -1 --format=%H --grep='(#8)$' v1.3.0 2>/dev/null)
if git -C $S log --format=%B v1.3.0..main 2>/dev/null | grep -q "This reverts commit $culprit"; then
  ok 'the change that introduced the fault is undone by a revert commit that names it'
else
  bad 'no commit on main since v1.3.0 reverts the change that introduced the fault'
fi
expect 'the embedding weight is still 0.8 on main (an unrelated change was not reverted)' \
  sh -c "git -C $S show main:router/scoring.py | grep -qx 'EMBED_WEIGHT = 0.8'"
expect 'keyword hits are still counted case-insensitively on main' \
  sh -c "git -C $S show main:router/keywords.py | grep -q 'text.lower()'"

n=$(git -C $S log --first-parent --format=%s v1.3.0..main 2>/dev/null | grep -Evc '(\(#[0-9]+\)$|^Merge pull request #[0-9]+ )')
if [ "$n" = 0 ] && [ "$(git -C $S rev-list --count v1.3.0..main 2>/dev/null)" != 0 ]; then
  ok 'everything on main since v1.3.0 arrived through a pull request'
else
  bad 'main has commits since v1.3.0 that did not arrive through a pull request (../pr merge)'
fi

expect 'the tag v1.3.1 exists on the server' git -C $S rev-parse -q --verify refs/tags/v1.3.1
if [ "$(git -C $S cat-file -t refs/tags/v1.3.1 2>/dev/null)" = tag ]; then ok 'v1.3.1 is an annotated tag'; else bad 'v1.3.1 is not an annotated tag'; fi
expect 'v1.3.1 is on main and later than v1.3.0' \
  sh -c "git -C $S merge-base --is-ancestor v1.3.1^{commit} main && git -C $S merge-base --is-ancestor v1.3.0 v1.3.1^{commit} && [ \"\$(git -C $S rev-parse v1.3.1^{commit})\" != \"\$(git -C $S rev-parse v1.3.0^{commit})\" ]"
expect 'the sample message goes to a human agent in v1.3.1' py_true $S 'v1.3.1^{commit}' "$SAMPLE"
expect 'the embedding weight is 0.8 in v1.3.1' \
  sh -c "git -C $S show v1.3.1:router/scoring.py | grep -qx 'EMBED_WEIGHT = 0.8'"
expect_not 'no bisect, revert or merge is left in progress in you/' in_progress you
check_end
