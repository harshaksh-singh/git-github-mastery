#!/usr/bin/env bash
# Read-only verification of gate 2, hands-on variant B. Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/check-lib.bash"
check_begin g2-b gate-2-branching/variant-b "${1:-}"
B=feature/dedupe-window
srv() { git -C server.git rev-parse -q --verify "refs/heads/$1" 2>/dev/null; }
loc() { git -C you rev-parse -q --verify "$1" 2>/dev/null; }
expect_not 'the stale remote-tracking ref origin/hotfix is gone' git -C you show-ref --verify -q refs/remotes/origin/hotfix
expect_eq 'origin/hotfix/retry-storm exists in your clone and equals the server' "$(loc refs/remotes/origin/hotfix/retry-storm)" "$(srv hotfix/retry-storm)"
expect "HEAD is on the local branch $B" on_branch you $B
expect_eq "its upstream is origin/$B" "$(git -C you rev-parse --abbrev-ref "$B@{upstream}" 2>/dev/null)" origin/$B
expect_eq 'the server has the same commit as your branch' "$(srv $B)" "$(loc refs/heads/$B)"
expect "Asha's commits on the server branch were not rewritten" git -C server.git merge-base --is-ancestor "$(noted asha)" refs/heads/$B
for s in 'Add seen_recently' 'Test seen_recently on an unknown key'; do
  expect_eq "the server branch has \"$s\" exactly once" "$(count_subject server.git refs/heads/$B "$s")" 1
done
expect 'the server branch has your code and Asha'"'"'s README' sh -c "git -C server.git cat-file -e refs/heads/$B:test_dedupe.py && git -C server.git cat-file -e refs/heads/$B:README.md"
expect_eq 'main on the server is untouched' "$(srv main)" "$(noted main)"
expect_eq 'your main equals main on the server' "$(loc refs/heads/main)" "$(noted main)"
expect 'nothing is staged, modified or untracked in you/' clean_tree you
expect_not 'no operation is left in progress' in_progress you
check_end
