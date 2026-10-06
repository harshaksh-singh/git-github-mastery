#!/usr/bin/env bash
# Read-only verification of the final-test lab "recovery". Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../final-lib/check-lib.bash"
check_begin recovery "${1:-}"
R=chunkstore
B=spike/semantic-overlap
expect_eq "the branch $B is back at its last commit, with the original commit ID" "$(rev $R "refs/heads/$B")" "$(noted spike)"
expect_eq 'main has not moved' "$(rev $R refs/heads/main)" "$(noted main)"
expect 'HEAD is on main' on_branch $R main
want=$(printf 'size: 512\noverlap: 128\nmin_chunk: 32\n' | git hash-object --stdin)
expect_eq 'config/chunking.yaml in the working tree has the stashed edit' "$(git -C $R hash-object config/chunking.yaml 2>/dev/null)" "$want"
expect_eq 'the edit is not staged and nothing else is changed' "$(git -C $R status --porcelain --untracked-files=all 2>/dev/null)" ' M config/chunking.yaml'
expect_not 'no operation is left in progress' in_progress $R
check_end
