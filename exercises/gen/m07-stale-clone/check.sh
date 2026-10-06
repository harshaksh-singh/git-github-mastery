#!/usr/bin/env bash
# Read-only verification of Exercise 7.9. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m07-stale-clone "${1:-}"
S=server.git; R=you
expect 'main on the server still contains what Asha pushed' git -C $S merge-base --is-ancestor "$(noted server_main)" refs/heads/main
expect_eq 'the TTL commit is on the server main exactly once' "$(count_subject $S refs/heads/main 'Cache embeddings for 24 hours')" 1
expect_eq 'no merge commit was added to main' "$(git -C $S rev-list --merges --count "$(noted server_main)"..refs/heads/main 2>/dev/null)" 0
expect 'the server main has the 24-hour TTL' sh -c "git -C $S show refs/heads/main:cache/store.py | grep -Fxq 'TTL_SECONDS = 86400'"
expect_eq 'your local main is what the server has' "$(git -C $R rev-parse -q --verify refs/heads/main)" "$(git -C $S rev-parse -q --verify refs/heads/main)"
expect_eq 'feature/tokenizer on the server has all three commits, unchanged' "$(git -C $S rev-parse -q --verify refs/heads/feature/tokenizer)" "$(noted tokenizer_tip)"
expect_eq 'your local feature/tokenizer is unchanged' "$(git -C $R rev-parse -q --verify refs/heads/feature/tokenizer)" "$(noted tokenizer_tip)"
expect_eq 'feature/tokenizer follows the remote origin' "$(git -C $R config get branch.feature/tokenizer.remote)" origin
expect_eq 'feature/tokenizer follows the branch of the same name' "$(git -C $R config get branch.feature/tokenizer.merge)" refs/heads/feature/tokenizer
expect_not 'the stale remote-tracking branch origin/feature/lru is pruned' git -C $R rev-parse -q --verify refs/remotes/origin/feature/lru
expect_not 'the local branch feature/lru is deleted' git -C $R rev-parse -q --verify refs/heads/feature/lru
expect_not 'nothing is left in progress' in_progress $R
expect 'your working tree is clean' clean_tree $R
check_end
