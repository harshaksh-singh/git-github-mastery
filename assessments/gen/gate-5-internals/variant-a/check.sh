#!/usr/bin/env bash
# Read-only verification of gate 5, hands-on variant A. Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/check-lib.bash"
check_begin g5-a gate-5-internals/variant-a "${1:-}"
R=ravi
every_pack_has_idx() { local p n=0; for p in $R/.git/objects/pack/*.pack; do [ -f "$p" ] || continue; n=$((n + 1)); [ -f "${p%.pack}.idx" ] || return 1; done; [ "$n" -gt 0 ]; }
expect 'every pack has its index' every_pack_has_idx
expect_not 'no index.lock is left' test -e $R/.git/index.lock
expect_eq 'git fsck reports nothing' "$(git -C $R fsck --no-dangling 2>&1; echo "rc=$?")" 'rc=0'
expect 'HEAD is on main' on_branch $R main
expect_eq "main still has Ravi's commit on top" "$(git -C $R rev-parse -q --verify refs/heads/main 2>/dev/null)" "$(noted head)"
expect_eq 'the staged file is still staged, with the same blob' "$(git -C $R rev-parse -q --verify :sync/manifest.py 2>/dev/null)" "$(noted blob)"
expect 'that blob can be read' git -C $R cat-file -p "$(noted blob)"
expect_eq 'git status reports the staged file and nothing else' "$(git -C $R status --porcelain --untracked-files=all 2>/dev/null)" 'A  sync/manifest.py'
expect_eq 'the clone is no longer shallow' "$(git -C $R rev-parse --is-shallow-repository 2>/dev/null)" false
expect_eq 'the whole history is there' "$(git -C $R rev-list --count main 2>/dev/null)" 5
expect_eq 'git describe finds the release tag' "$(git -C $R describe --abbrev=0 2>/dev/null)" v1.2.0
expect_eq 'the server has not been changed' "$(git -C server.git rev-parse -q --verify refs/heads/main 2>/dev/null)" "$(noted server_main)"
check_end
