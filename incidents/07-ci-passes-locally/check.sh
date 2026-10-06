#!/usr/bin/env bash
# Read-only verification of the fix for incident 7. Exit status 0 means the files are fixed.
# It inspects the branch fix/ci-checkout on the server. It cannot run the workflow.
. "$(dirname "${BASH_SOURCE[0]}")/../lib/check-lib.bash"
check_begin 07-ci-passes-locally "${1:-}"
S=server.git
B=fix/ci-checkout
W=.github/workflows/ci.yml
expect "the server has the branch $B" git -C $S rev-parse --verify -q refs/heads/$B
expect 'the branch is based on main' git -C $S merge-base --is-ancestor main $B
wf=$(git -C $S show $B:$W 2>/dev/null | grep -v '^ *#')
if printf '%s\n' "$wf" | grep -Eq '^ +fetch-depth: *0 *$'; then
  ok 'the checkout step fetches the full history and the tags (fetch-depth: 0)'
else
  bad 'the checkout step still makes a shallow clone without tags (no fetch-depth: 0)'
fi
expect 'actions/checkout is still pinned to a full commit SHA' sh -c "git -C $S show $B:$W | grep -Eq 'actions/checkout@[0-9a-f]{40}'"
expect 'the workflow still declares permissions' sh -c "git -C $S show $B:$W | grep -q '^permissions:'"
name=$(git -C $S show $B:reports/render.py 2>/dev/null | sed -n 's/.*"\([A-Za-z]*\.md\.tmpl\)".*/\1/p' | head -1)
if [ -n "$name" ] && git -C $S ls-tree -r --name-only $B | grep -Fxq "templates/$name"; then
  ok "reports/render.py opens templates/$name, which is tracked with exactly that spelling"
else
  bad "reports/render.py opens templates/${name:-?}, and no tracked file has exactly that spelling"
fi
expect 'the release tag v1.4.0 is still on the server' git -C $S rev-parse --verify -q refs/tags/v1.4.0
check_end
