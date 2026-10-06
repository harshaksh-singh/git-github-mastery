#!/usr/bin/env bash
# Read-only verification of the recovery of incident 2. Exit status 0 means recovered.
. "$(dirname "${BASH_SOURCE[0]}")/../lib/check-lib.bash"
check_begin 02-force-push-wrong-branch "${1:-}"
S=server.git
for s in 'Add loader' 'Add row validation' 'Reject rows without a timestamp' 'Close the input file after loading'; do
  expect "main on the server has \"$s\"" has_subject $S main "$s"
done
expect_not 'main on the server has no WIP commit' sh -c "git -C $S log --format=%s main | grep -q '^WIP'"
expect 'the server has a branch feature/dedupe' git -C $S rev-parse --verify -q refs/heads/feature/dedupe
expect 'feature/dedupe on the server has "WIP dedupe by id"' has_subject $S feature/dedupe 'WIP dedupe by id'
expect 'feature/dedupe on the server has the amended commit' has_subject $S feature/dedupe 'WIP config flag and readable dedupe, tests still red'
up=$(git -C asha rev-parse --abbrev-ref 'feature/dedupe@{upstream}' 2>/dev/null)
if [ "$up" = origin/main ]; then bad "in asha/, feature/dedupe still has origin/main as its upstream"; else ok "in asha/, the upstream of feature/dedupe is no longer origin/main (now: ${up:-none})"; fi
pd=$(git -C asha config get push.default 2>/dev/null)
if [ "$pd" = upstream ] || [ "$pd" = matching ]; then bad "in asha/, push.default is still \"$pd\""; else ok "in asha/, push.default is ${pd:-unset (simple)}"; fi
check_end
