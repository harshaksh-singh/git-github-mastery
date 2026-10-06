#!/usr/bin/env bash
# Read-only verification of Exercise 8.10. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m08-missing-half "${1:-}"
S=server.git; M=refs/heads/main; F="$(noted feature_tip)"
expect 'main on the server still contains every commit it had' git -C $S merge-base --is-ancestor "$(noted server_main)" $M
for p in runner/batch.py runner/parallel.py runner/limits.py docs/batch-eval.md; do
  expect_eq "$p on main is the version of the feature branch" "$(git -C $S rev-parse -q --verify $M:$p)" "$(git -C $S rev-parse -q --verify $F:$p)"
done
expect 'the 45-second timeout of main is kept' sh -c "git -C $S show $M:settings.yaml | grep -Fxq 'timeout_s: 45'"
expect_eq 'the feature branch on the server was not moved' "$(git -C $S rev-parse -q --verify refs/heads/feature/batch-eval)" "$F"
expect_eq 'your local main is what the server has' "$(git -C you rev-parse -q --verify $M)" "$(git -C $S rev-parse -q --verify $M)"
expect_not 'nothing is left in progress in your clone' in_progress you
expect 'your working tree is clean' clean_tree you
check_end
