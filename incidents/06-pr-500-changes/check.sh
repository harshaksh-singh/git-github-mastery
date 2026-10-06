#!/usr/bin/env bash
# Read-only verification of the recovery of incident 6. Exit status 0 means recovered.
. "$(dirname "${BASH_SOURCE[0]}")/../lib/check-lib.bash"
check_begin 06-pr-500-changes "${1:-}"
S=server.git
B=feature/snippet-highlight
expect 'the server still has the feature branch' git -C $S rev-parse --verify -q refs/heads/$B
for s in 'Add snippet highlighting' 'Test snippet highlighting' 'Escape HTML in snippets' 'Highlight every query term'; do
  n=$(git -C $S log --format=%s main..$B 2>/dev/null | grep -Fxc "$s")
  if [ "$n" = 1 ]; then ok "\"$s\" is in the pull request exactly once"; else bad "\"$s\" is in the pull request $n times (expected once)"; fi
done
n=$(git -C $S rev-list --count main..$B 2>/dev/null)
if [ "$n" = 4 ]; then ok 'the pull request lists four commits'; else bad "the pull request lists $n commits (expected 4)"; fi
n=$(git -C $S diff --name-only main...$B 2>/dev/null | grep -c .)
if [ "$n" = 2 ]; then ok 'the pull request changes two files'; else bad "the pull request changes $n files (expected 2)"; fi
expect_not 'no commit of develop is reachable from the feature branch' sh -c "git -C $S log --format=%s main..$B | grep -Fxq 'Regenerate golden fixtures'"
n=$(git -C $S rev-list --count --merges main..$B 2>/dev/null)
if [ "$n" = 0 ]; then ok 'the feature branch contains no merge commit'; else bad "the feature branch contains $n merge commit(s); a reverted merge is not a removed merge"; fi
expect 'search/highlight.py handles every query term' sh -c "git -C $S show $B:search/highlight.py | grep -q 'for term in terms'"
expect 'develop on the server is untouched' has_subject $S develop 'Regenerate golden fixtures'
expect 'main on the server is untouched' sh -c "[ \"\$(git -C $S log -1 --format=%s main)\" = 'Add tokenizer test' ]"
check_end
