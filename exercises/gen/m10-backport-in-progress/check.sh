#!/usr/bin/env bash
# Read-only verification of Exercise 10.9. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m10-backport-in-progress "${1:-}"
R=vocab-service; B=refs/heads/release/3.2
expect_not 'no cherry-pick is in progress' in_progress $R
expect 'the release line still starts from its own history' git -C $R merge-base --is-ancestor "$(noted release_base)" $B
expect_eq 'exactly the three security fixes were added, in the order of main' "$(git -C $R log --reverse --format=%s "$(noted release_base)"..$B 2>/dev/null | tr '\n' '|')" 'Security: reject NUL bytes in the input|Security: cap the input length before tokenizing|Security: strip control characters|'
for s in 'Security: reject NUL bytes in the input' 'Security: cap the input length before tokenizing' 'Security: strip control characters'; do
  src=$(id_of $R refs/heads/main "$s"); c=$(id_of $R $B "$s")
  expect "\"$s\" records the commit of main it came from" sh -c "git -C $R log -1 --format=%b ${c:-HEAD} | grep -Fxq '(cherry picked from commit $src)'"
done
expect 'the release keeps its own input limit' sh -c "git -C $R show $B:svc/limits.py | grep -Fxq 'MAX_INPUT = 2048'"
expect 'the length check arrived' sh -c "git -C $R show $B:svc/limits.py | grep -Fq 'if len(text) > MAX_INPUT:'"
expect_not 'the limit of main did not arrive' sh -c "git -C $R show $B:svc/limits.py | grep -q 4096"
expect_eq 'svc/tokenize.py has both fixes: it equals the file on main' "$(git -C $R rev-parse -q --verify $B:svc/tokenize.py)" "$(git -C $R rev-parse -q --verify refs/heads/main:svc/tokenize.py)"
expect_not 'the streaming endpoint was not backported' git -C $R cat-file -e $B:svc/stream.py
expect_not 'the batch endpoint was not backported' git -C $R cat-file -e $B:svc/batch.py
expect_not 'no conflict marker is committed' git -C $R grep -q -e '^<<<<<<<' -e '^=======$' -e '^>>>>>>>' $B
expect 'working tree and index are clean' clean_tree $R
check_end
