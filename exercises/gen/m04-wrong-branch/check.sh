#!/usr/bin/env bash
# Read-only verification of Exercise 4.9. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m04-wrong-branch "${1:-}"
R=you
expect_eq 'feature/rate-limit points at the third commit, unchanged' "$(git -C $R rev-parse -q --verify refs/heads/feature/rate-limit)" "$(noted tip)"
expect_eq 'the server has feature/rate-limit at the same commit' "$(git -C server.git rev-parse -q --verify refs/heads/feature/rate-limit)" "$(noted tip)"
expect_eq 'local main is the commit that main has on the server' "$(git -C $R rev-parse -q --verify refs/heads/main)" "$(noted server_main)"
expect_eq 'main on the server did not move' "$(git -C server.git rev-parse -q --verify refs/heads/main)" "$(noted server_main)"
expect_eq 'HEAD is on feature/rate-limit' "$(git -C $R symbolic-ref -q HEAD)" refs/heads/feature/rate-limit
expect_eq 'the uncommitted edit is still in the working tree' "$(git -C $R hash-object gateway/limits.py)" "$(noted wip_blob)"
expect_eq 'the edit is still uncommitted' "$(git -C $R status --porcelain)" ' M gateway/limits.py'
expect_not 'the merged branch feature/old-cache is deleted' git -C $R rev-parse -q --verify refs/heads/feature/old-cache
expect_eq 'the unmerged branch spike/token-bucket is kept' "$(git -C $R rev-parse -q --verify refs/heads/spike/token-bucket)" "$(noted spike)"
check_end
