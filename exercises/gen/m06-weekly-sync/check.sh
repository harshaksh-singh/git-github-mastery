#!/usr/bin/env bash
# Read-only verification of Exercise 6.10. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m06-weekly-sync "${1:-}"
S=server.git
expect 'main on the server still contains its old history' git -C $S merge-base --is-ancestor "$(noted server_main)" refs/heads/main
expect_eq 'develop on the server was not rewritten or moved' "$(git -C $S rev-parse -q --verify refs/heads/develop)" "$(noted server_develop)"
expect 'develop is an ancestor of main on the server: the next sync starts from here' git -C $S merge-base --is-ancestor refs/heads/develop refs/heads/main
expect_eq 'sampler/config.py on main equals the one on develop' "$(git -C $S rev-parse -q --verify refs/heads/main:sampler/config.py)" "$(git -C $S rev-parse -q --verify refs/heads/develop:sampler/config.py)"
expect 'main still has the hotfix (the clamp)' sh -c "git -C $S show refs/heads/main:sampler/sample.py | grep -Fq 'temperature = min(max(temperature, 0.01), 2.0)'"
expect 'main has the seeded generator of this week' sh -c "git -C $S show refs/heads/main:sampler/sample.py | grep -Fq 'def seeded(seed):'"
expect_not 'no conflict marker is committed' git -C $S grep -q -e '^<<<<<<<' -e '^=======$' -e '^>>>>>>>' refs/heads/main
expect_eq 'your local main is what the server has' "$(git -C you rev-parse -q --verify refs/heads/main)" "$(git -C $S rev-parse -q --verify refs/heads/main)"
expect_not 'no merge is left in progress in your clone' in_progress you
expect 'your working tree is clean' clean_tree you
check_end
