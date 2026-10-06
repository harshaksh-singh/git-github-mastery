#!/usr/bin/env bash
# Read-only verification of Exercise 7.10. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m07-hotfix-not-deployed "${1:-}"
S=server.git; B=refs/heads/release/2.4
expect "Asha's changelog commit is still in release/2.4 on the server" git -C $S merge-base --is-ancestor "$(noted changelog)" $B
expect_eq 'the hotfix is on the server release branch exactly once' "$(count_subject $S $B 'Split embedding requests into batches of 96')" 1
expect 'the released code batches the requests' sh -c "git -C $S show $B:gateway/embed.py | grep -Fq 'for i in range(0, len(texts), BATCH):'"
expect 'the changelog entry for 2.4.1 is still there' sh -c "git -C $S show $B:CHANGELOG.md | grep -Fxq '## 2.4.1'"
expect_eq "Ravi's clone pushes to the repository it fetches from" "$(git -C ravi remote get-url --push origin)" "$(git -C ravi remote get-url origin)"
expect_eq "Ravi's fetch URL is still the company server" "$(git -C ravi remote get-url origin)" ../server.git
expect_eq "Ravi's local release/2.4 is what the server has" "$(git -C ravi rev-parse -q --verify $B)" "$(git -C $S rev-parse -q --verify $B)"
expect_eq 'nothing further was pushed to the old host' "$(git -C old-server.git rev-parse -q --verify $B)" "$(noted hotfix)"
expect_not "nothing is left in progress in Ravi's clone" in_progress ravi
expect "Ravi's working tree is clean" clean_tree ravi
check_end
