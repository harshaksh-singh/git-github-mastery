#!/usr/bin/env bash
# Read-only verification of Exercise 8.9. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m08-undo-mix "${1:-}"
S=server.git; R=you; M=refs/heads/main
expect 'main on the server still contains every commit it had' git -C $S merge-base --is-ancestor "$(noted server_main)" $M
expect_eq 'the commit that lowered the pass mark is still in history' "$(count_subject $S $M 'Lower the pass mark to 0.5')" 1
expect 'the pass mark on the server is 0.7' sh -c "git -C $S show $M:grader/threshold.py | grep -Fxq 'PASS_MARK = 0.7'"
expect 'the timeout on the server is 60 seconds' sh -c "git -C $S show $M:configs/grader.yaml | grep -Fxq 'timeout_s: 60'"
expect 'the timeout change has its own commit with the requested title' has_subject $S $M 'Raise the grader timeout to 60 seconds'
t=$(id_of $S $M 'Raise the grader timeout to 60 seconds')
expect_eq 'that commit changes configs/grader.yaml and nothing else' "$(git -C $S show --format= --name-only "${t:-HEAD}" 2>/dev/null)" configs/grader.yaml
expect_eq 'the parser on the server is the original one' "$(git -C $S rev-parse -q --verify $M:grader/parser.py)" "$(noted parser_blob)"
expect_eq 'the mixed commit is on no branch of your clone' "$(git -C $R log --all --format=%s | grep -Fxc 'Update config and try new parser')" 0
expect_eq 'your local main is what the server has' "$(git -C $R rev-parse -q --verify $M)" "$(git -C $S rev-parse -q --verify $M)"
expect_eq 'the experiment is still in your working tree' "$(git -C $R hash-object grader/parser.py)" "$(noted experiment_blob)"
expect_eq 'the experiment is an unstaged modification, and the only change' "$(git -C $R status --porcelain)" ' M grader/parser.py'
check_end
