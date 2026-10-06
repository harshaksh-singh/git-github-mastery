#!/usr/bin/env bash
# Read-only verification of the recovery of incident 9. Exit status 0 means recovered.
. "$(dirname "${BASH_SOURCE[0]}")/../lib/check-lib.bash"
check_begin 09-misunderstood-conflict "${1:-}"
S=server.git
F=main:limiter/bucket.py
has() { git -C $S show $F 2>/dev/null | grep -Fq -- "$1"; }
expect 'bucket.py on main caps the bucket at BURST' has 'min(BURST, bucket.tokens + (now - bucket.ts) * rate)'
expect 'bucket.py on main has the lowered default rate under its new name' has 'DEFAULT_RATE = 50'
expect 'bucket.py on main still looks up the rate per tenant' has 'refill(bucket, now, rate_for(key))'
expect_not 'bucket.py on main has no leftover "RATE = 50" or "DEFAULT_RATE = 100"' sh -c "git -C $S show $F | grep -Eq '^RATE = 50|^DEFAULT_RATE = 100'"
expect_not 'bucket.py on main has no conflict markers' sh -c "git -C $S show $F | grep -Eq '^(<<<<<<<|=======|>>>>>>>)'"
expect 'limiter/tenants.py is still on main' git -C $S cat-file -e main:limiter/tenants.py
for s in 'Cap the bucket at BURST tokens' 'Halve the default rate after the overload' 'Look up the rate per tenant' 'Merge pull request #17 from feature/per-tenant-limits' 'Add limiter metrics'; do
  expect "main still has \"$s\" (history was not rewritten)" has_subject $S main "$s"
done
expect 'the faulty merge is still in the history of main' sh -c "git -C $S log --merges --format=%s main | grep -q \"^Merge remote-tracking branch 'origin/main' into feature/per-tenant-limits\""
check_end
