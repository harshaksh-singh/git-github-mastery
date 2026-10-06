#!/usr/bin/env bash
# Read-only verification of Exercise 3.9. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m03-wrong-commit "${1:-}"
R=scorer-service
expect_eq 'the corrected commit has the same parent as the original' "$(git -C $R rev-parse -q --verify HEAD~1)" "$(noted parent)"
expect_eq 'the branch has exactly three commits' "$(git -C $R rev-list --count main 2>/dev/null)" 3
expect_eq 'HEAD is on main' "$(git -C $R symbolic-ref -q HEAD)" refs/heads/main
expect_eq 'the author is Ravi Menon <ravi@example.com>' "$(git -C $R log -1 --format='%an <%ae>')" 'Ravi Menon <ravi@example.com>'
expect_eq 'the author date is the original one' "$(git -C $R log -1 --format=%at)" "$(noted author_date)"
expect_eq 'the title is corrected' "$(git -C $R log -1 --format=%s)" 'Add retry budget to the scorer'
expect 'the body is unchanged' sh -c "git -C $R log -1 --format=%b | grep -q 'A batch is retried until the budget of the run is used up'"
expect_eq 'the Reviewed-by trailer is still a trailer' "$(git -C $R log -1 --format='%(trailers:key=Reviewed-by,valueonly)' | head -1)" 'Asha Rao <asha@example.com>'
expect_not 'debug.log is not in the commit' git -C $R cat-file -e HEAD:debug.log
expect 'debug.log is still in the working tree' test -f $R/debug.log
expect_eq 'debug.log is not staged either' "$(git -C $R ls-files debug.log)x" x
expect_eq 'scorer/retry.py is committed as before' "$(git -C $R rev-parse -q --verify HEAD:scorer/retry.py)" "$(noted retry_blob)"
expect_eq 'configs/scorer.yaml is committed as before' "$(git -C $R rev-parse -q --verify HEAD:configs/scorer.yaml)" "$(noted config_blob)"
expect 'no tracked file differs from the commit' git -C $R diff --quiet HEAD
check_end
