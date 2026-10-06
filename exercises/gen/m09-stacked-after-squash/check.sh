#!/usr/bin/env bash
# Read-only verification of Exercise 9.9. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m09-stacked-after-squash "${1:-}"
R=policy-engine; B=refs/heads/feat/pii-redaction
expect_not 'no rebase is in progress' in_progress $R
expect_eq 'HEAD is on feat/pii-redaction' "$(git -C $R symbolic-ref -q HEAD)" $B
expect_eq 'main did not move' "$(git -C $R rev-parse -q --verify refs/heads/main)" "$(noted main_tip)"
expect_eq 'the branch starts at the tip of main' "$(git -C $R merge-base refs/heads/main $B 2>/dev/null)" "$(noted main_tip)"
expect_eq 'the branch has your two commits and nothing else, in order' "$(git -C $R log --reverse --format=%s refs/heads/main..$B 2>/dev/null | tr '\n' '|')" 'Add redaction of matched spans|Redact email addresses in the audit log|'
expect_eq 'redact.py is as you wrote it' "$(git -C $R rev-parse -q --verify $B:redact.py)" "$(noted redact_blob)"
expect_eq 'audit_log.py is as you wrote it' "$(git -C $R rev-parse -q --verify $B:audit_log.py)" "$(noted log_blob)"
expect 'rules/ and engine.py are exactly what main has' git -C $R diff --quiet refs/heads/main $B -- rules engine.py
expect 'working tree and index are clean' clean_tree $R
check_end
