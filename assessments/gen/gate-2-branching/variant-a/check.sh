#!/usr/bin/env bash
# Read-only verification of gate 2, hands-on variant A. Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/check-lib.bash"
check_begin g2-a gate-2-branching/variant-a "${1:-}"
srv() { git -C server.git rev-parse -q --verify "refs/heads/$1" 2>/dev/null; }
loc() { git -C you rev-parse -q --verify "$1" 2>/dev/null; }
expect_not 'you/ has no local branch called origin/main' git -C you show-ref --verify -q refs/heads/origin/main
expect_eq 'main on the server is where Asha left it' "$(srv main)" "$(noted main)"
expect_eq 'your main equals main on the server' "$(loc refs/heads/main)" "$(noted main)"
expect_eq 'origin/main in your clone equals main on the server' "$(loc refs/remotes/origin/main)" "$(noted main)"
expect_eq 'feature/mmr-rerank still has your two commits and nothing else new' "$(loc refs/heads/feature/mmr-rerank)" "$(noted mmr)"
expect_eq 'feature/mmr-rerank is on the server under its own name' "$(srv feature/mmr-rerank)" "$(noted mmr)"
expect_eq 'its upstream is origin/feature/mmr-rerank' "$(git -C you rev-parse --abbrev-ref 'feature/mmr-rerank@{upstream}' 2>/dev/null)" origin/feature/mmr-rerank
expect_not 'the stale remote-tracking ref origin/feature/bm25-tuning is gone' git -C you show-ref --verify -q refs/remotes/origin/feature/bm25-tuning
expect_not 'the merged local branch feature/bm25-tuning is deleted' git -C you show-ref --verify -q refs/heads/feature/bm25-tuning
expect_not 'feature/bm25-tuning was not put back on the server' git -C server.git show-ref --verify -q refs/heads/feature/bm25-tuning
expect_eq 'spike/colbert is back on the server with both commits' "$(srv spike/colbert)" "$(noted spike)"
expect_eq 'your local spike/colbert still has both commits' "$(loc refs/heads/spike/colbert)" "$(noted spike)"
expect 'nothing is staged, modified or untracked in you/' clean_tree you
expect_not 'no operation is left in progress' in_progress you
check_end
