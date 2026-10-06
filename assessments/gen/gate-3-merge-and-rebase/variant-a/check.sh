#!/usr/bin/env bash
# Read-only verification of gate 3, hands-on variant A. Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/check-lib.bash"
check_begin g3-a gate-3-merge-and-rebase/variant-a "${1:-}"
R=you; F=feature/overlap
S1='Add overlap to the splitter'; S2='Fix off-by-one in window end'
expect_not 'no rebase or cherry-pick is in progress' in_progress $R
expect "HEAD is on $F" on_branch $R $F
expect_eq 'main is where the server has it, locally and on the server' "$(git -C $R rev-parse -q --verify refs/heads/main 2>/dev/null) $(git -C server.git rev-parse -q --verify refs/heads/main 2>/dev/null)" "$(noted main) $(noted main)"
expect_eq "$F starts at the tip of main" "$(git -C $R merge-base main $F 2>/dev/null)" "$(noted main)"
expect_eq "$F has exactly these two commits, in this order" "$(git -C $R log --reverse --format=%s main..$F 2>/dev/null | tr '\n' '|')" "$S1|$S2|"
split() { git -C $R show "$F:chunker/split.py" 2>/dev/null; }
expect 'the splitter has both parameters' sh -c "git -C $R show $F:chunker/split.py | grep -Fxq 'def split(text, max_len=512, overlap=0):'"
expect 'the step is max_len - overlap' sh -c "git -C $R show $F:chunker/split.py | grep -Fxq '        start += max_len - overlap'"
expect_not 'the old parameter name and the conflict markers are gone' sh -c "git -C $R show $F:chunker/split.py | grep -Eq 'size|^<<<<<<<|^=======|^>>>>>>>'"
expect 'the test file is part of the first commit' git -C $R cat-file -e "$F~1:tests/test_split.py"
n=$(git -C $R rev-list --count origin/release/1.2..release/1.2 2>/dev/null)
expect_eq 'release/1.2 has exactly one new commit' "$n" 1
expect_eq 'it is the off-by-one fix' "$(git -C $R log -1 --format=%s release/1.2 2>/dev/null)" "$S2"
expect 'its message names the commit on the feature branch it was picked from' sh -c "git -C $R log -1 --format=%b release/1.2 | grep -Fxq '(cherry picked from commit $(git -C $R rev-parse -q --verify $F 2>/dev/null))'"
expect 'release/1.2 has the fixed window helper' sh -c "git -C $R show release/1.2:chunker/window.py | grep -Fq 'min(start + size, total)'"
expect_not 'release/1.2 did not receive the overlap feature' sh -c "git -C $R show release/1.2:chunker/split.py | grep -q overlap"
expect_eq 'release/1.2 on the server has not moved' "$(git -C server.git rev-parse -q --verify refs/heads/release/1.2 2>/dev/null)" "$(noted release)"
expect 'nothing is staged, modified or untracked' clean_tree $R
check_end
