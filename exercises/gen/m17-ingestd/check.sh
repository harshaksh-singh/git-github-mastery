#!/usr/bin/env bash
# Read-only verification of exercise 17.9. Exit status 0 means repaired.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
check_begin m17-ingestd you/.git "${1:-}"
R=you
same 'HEAD is a symbolic ref to feature/batching' "$(git -C $R symbolic-ref -q HEAD 2>/dev/null)" refs/heads/feature/batching
expect_not 'no stale index.lock is left' test -e $R/.git/index.lock
same 'the unpushed commit is still the tip of the branch' "$(git -C $R log -1 --format=%s feature/batching 2>/dev/null)" 'Match the configured batch size'
same 'the uncommitted README edit is still in the working tree' "$(git -C $R status --porcelain 2>/dev/null)" ' M README.md'
same 'remote.origin.url is ../server.git' "$(git -C $R config get remote.origin.url 2>/dev/null)" ../server.git
same 'remote.origin.fetch is the default refspec' "$(git -C $R config get remote.origin.fetch 2>/dev/null)" '+refs/heads/*:refs/remotes/origin/*'
expect 'the remote answers' git -C $R ls-remote origin
same 'main tracks origin/main' "$(git -C $R rev-parse --abbrev-ref 'main@{upstream}' 2>/dev/null)" origin/main
same 'feature/batching tracks origin/feature/batching' "$(git -C $R rev-parse --abbrev-ref 'feature/batching@{upstream}' 2>/dev/null)" origin/feature/batching
ct=$(git -C $R log -1 --format=%ct feature/batching 2>/dev/null)
if [ -n "$ct" ] && [ "$ct" -lt 1789965000 ]; then ok 'this is the original clone (the unpushed commit is the original object)'; else bad 'this is the original clone (the unpushed commit is the original object)'; fi
expect 'git fsck finds no problem' git -C $R fsck --no-dangling
check_end
