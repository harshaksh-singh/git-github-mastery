#!/usr/bin/env bash
# Read-only verification of exercise 14.9. Exit status 0 means recovered.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
check_begin m14-redactor redactor/.git "${1:-}"
R=redactor; B=hotfix/pii-patterns
same 'the branch hotfix/pii-patterns has two commits on top of v2.1.0' "$(git -C $R rev-list --count v2.1.0..$B 2>/dev/null)" 2
same 'the first is "Redact ten-digit phone numbers"' "$(git -C $R log -1 --format=%s $B~1 2>/dev/null)" 'Redact ten-digit phone numbers'
same 'the second is "Redact IBANs"' "$(git -C $R log -1 --format=%s $B 2>/dev/null)" 'Redact IBANs'
same 'the branch starts exactly at the release tag' "$(git -C $R rev-parse -q --verify "$B~2" 2>/dev/null)" "$(git -C $R rev-parse 'v2.1.0^{commit}')"
ct=$(git -C $R log -1 --format=%ct $B 2>/dev/null)
if [ -n "$ct" ] && [ "$ct" -lt 1789965000 ]; then ok 'they are the original commits, not copies'; else bad 'they are the original commits, not copies'; fi
same 'HEAD is still on feature/names' "$(git -C $R symbolic-ref -q --short HEAD)" feature/names
same 'feature/names still ends with "Start name detection"' "$(git -C $R log -1 --format=%s feature/names)" 'Start name detection'
expect_not 'the hotfix was not merged into feature/names' git -C $R merge-base --is-ancestor $B feature/names
same 'the working tree is clean' "$(git -C $R status --porcelain | wc -l | tr -d ' ')" 0
check_end
