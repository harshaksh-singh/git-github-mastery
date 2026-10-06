#!/usr/bin/env bash
# Read-only verification of exercise 18.9. Exit status 0 means done.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
check_begin m18-searchstack build/.git "${1:-}"
R=build; S=server.git
same 'the clone is no longer shallow' "$(git -C $R rev-parse --is-shallow-repository 2>/dev/null)" false
same 'main has its full history' "$(git -C $R rev-list --count origin/main 2>/dev/null)" "$(git -C $S rev-list --count main)"
same 'the fetch refspec covers every branch' "$(git -C $R config get --all remote.origin.fetch 2>/dev/null)" '+refs/heads/*:refs/remotes/origin/*'
same 'origin/release/0.2 is where the server has the branch' "$(git -C $R rev-parse -q --verify refs/remotes/origin/release/0.2 2>/dev/null)" "$(git -C $S rev-parse refs/heads/release/0.2)"
same 'both tags are present' "$(git -C $R tag | tr '\n' ' ')" 'v0.1.0 v0.2.0 '
expect_not 'tag fetching is no longer switched off (remote.origin.tagOpt)' git -C $R config get remote.origin.tagOpt
same 'git describe on main agrees with the server' "$(git -C $R describe origin/main 2>/dev/null)" "$(git -C $S describe main)"
expect 'git fsck finds no problem' git -C $R fsck --no-dangling
check_end
