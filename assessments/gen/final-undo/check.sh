#!/usr/bin/env bash
# Read-only verification of the final-test lab "undo". Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../final-lib/check-lib.bash"
check_begin undo "${1:-}"
S=server.git
a=$(noted asha)
new=$(rev $S refs/heads/main)
expect_eq "exactly one new commit sits on top of Asha's commit on the server" "$(rev $S 'refs/heads/main~1')" "$a"
want=$(printf 'highway: 1.0\ntoll: 1.5\narterial: 1.2\nlocal: 1.4\nferry: 3.0\n' | git hash-object --stdin)
expect_eq 'weights.yaml on the server has the corrected key and the ferry penalty' "$(rev $S main:weights.yaml)" "$want"
expect_eq 'the new commit changes weights.yaml and nothing else' "$(git -C $S diff --name-only "$a" refs/heads/main 2>/dev/null)" weights.yaml
expect_eq 'your main equals main on the server' "$(rev you refs/heads/main)" "$new"
expect_eq 'your origin/main equals main on the server' "$(rev you refs/remotes/origin/main)" "$new"
expect 'nothing is staged, modified or untracked in your clone' clean_tree you
expect_not 'no operation is left in progress' in_progress you
check_end
