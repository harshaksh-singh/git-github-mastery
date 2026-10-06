#!/usr/bin/env bash
# Read-only verification of the recovery of incident 8. Exit status 0 means recovered.
. "$(dirname "${BASH_SOURCE[0]}")/../lib/check-lib.bash"
check_begin 08-branch-disappeared "${1:-}"
S=server.git
B=feature/prompt-validation
expect "the server has the branch $B" git -C $S rev-parse --verify -q refs/heads/$B
expect 'the branch has "Validate prompt variables before save"' has_subject $S $B 'Validate prompt variables before save'
expect 'the branch is based on the current main' git -C $S merge-base --is-ancestor main $B
n=$(git -C $S rev-list --count main..$B 2>/dev/null)
if [ "$n" = 1 ]; then ok 'a pull request for the branch would list one commit'; else bad "a pull request for the branch would list $n commits (expected 1: the squashed work must not come back)"; fi
f=$(git -C $S diff --name-only main...$B 2>/dev/null | tr '\n' ' ')
if [ "$f" = 'registry/validate.py ' ]; then ok 'a pull request for the branch would change registry/validate.py only'; else bad "a pull request for the branch would change: ${f:-nothing}"; fi
want=$(printf 'import string\n\ndef variables(text):\n    return {f for _, f, _, _ in string.Formatter().parse(text) if f}\n\ndef validate(text, allowed):\n    unknown = variables(text) - set(allowed)\n    if unknown:\n        raise ValueError(f"unknown variables: {sorted(unknown)}")\n' | git hash-object --stdin)
have=$(git -C $S rev-parse -q --verify "$B:registry/validate.py" 2>/dev/null)
if [ "$want" = "$have" ]; then ok 'registry/validate.py has the content of the lost commit'; else bad 'registry/validate.py does not have the content of the lost commit'; fi
expect 'main on the server still ends with the squash merge' sh -c "[ \"\$(git -C $S log -1 --format=%s main)\" = 'Add prompt versioning (#42)' ]"
expect_not 'the merged branch was not pushed again' git -C $S rev-parse --verify -q refs/heads/feature/prompt-versioning
check_end
