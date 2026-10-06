#!/usr/bin/env bash
# Read-only verification of Exercise 1.9. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m01-unborn-main "${1:-}"
R=chunk-index
expect_eq 'HEAD is a symbolic ref to refs/heads/main' "$(git -C $R symbolic-ref -q HEAD)" refs/heads/main
expect_eq 'main points at the last commit of Friday' "$(git -C $R rev-parse -q --verify refs/heads/main)" "$(noted tip)"
expect_eq 'the history has exactly the three original commits' "$(git -C $R rev-list --count HEAD 2>/dev/null)" 3
expect_eq 'main is the only branch' "$(git -C $R for-each-ref --format='%(refname)' refs/heads | tr '\n' ' ')" 'refs/heads/main '
expect 'the working tree and the index match the commit' clean_tree $R
expect 'the object database is intact' git -C $R fsck --no-dangling
check_end
