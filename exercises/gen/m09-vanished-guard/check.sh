#!/usr/bin/env bash
# Read-only verification of Exercise 9.10. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m09-vanished-guard "${1:-}"
S=server.git; B=refs/heads/feat/abuse-filter
expect 'the branch on the server was not rewritten again' git -C $S merge-base --is-ancestor "$(noted rewritten_tip)" $B
expect_eq 'the lost change is on the branch exactly once' "$(git -C $S log --format=%s refs/heads/main..$B | grep -Fxc 'Reject empty messages before scoring')" 1
expect 'the endpoint rejects empty messages' sh -c "git -C $S show $B:api/moderate.py | grep -Fq 'if not message.strip():'"
expect 'the endpoint still rejects messages that are too long' sh -c "git -C $S show $B:api/moderate.py | grep -Fq 'if len(message) > 10000:'"
expect 'the scoring call is still there, once' sh -c "[ \"\$(git -C $S show $B:api/moderate.py | grep -Fc 'score = abuse.score(message)')\" = 1 ]"
expect_not 'no conflict marker is committed' git -C $S grep -q -e '^<<<<<<<' -e '^=======$' -e '^>>>>>>>' $B
expect 'the branch still contains the current main' git -C $S merge-base --is-ancestor refs/heads/main $B
expect_eq 'your local branch is what the server has' "$(git -C you rev-parse -q --verify $B)" "$(git -C $S rev-parse -q --verify $B)"
expect_not 'nothing is left in progress in your clone' in_progress you
expect 'your working tree is clean' clean_tree you
check_end
