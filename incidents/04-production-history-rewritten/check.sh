#!/usr/bin/env bash
# Read-only verification of the recovery of incident 4. Exit status 0 means recovered.
. "$(dirname "${BASH_SOURCE[0]}")/../lib/check-lib.bash"
check_begin 04-production-history-rewritten "${1:-}"
S=server.git
for s in 'Add invoice totals' 'Add tax calculation' 'Round tax to two decimals' 'Add currency formatting' 'Log the invoice id on failure' 'Add invoice PDF footer'; do
  expect "production on the server has \"$s\"" has_subject $S production "$s"
done
expect_not 'the squashed commit is no longer on production' has_subject $S production 'Tax calculation, formatting and logging'
expect 'the deployed tag is an ancestor of production again' git -C $S merge-base --is-ancestor 'deploy-2026-09-07^{commit}' production
expect 'billing/tax.py on production rounds to two decimals' sh -c "git -C $S show production:billing/tax.py | grep -q 'round(amount \* rate, 2)'"
expect 'billing/pdf.py is on production' git -C $S cat-file -e production:billing/pdf.py
tip=$(git -C $S rev-parse production)
for c in you asha ravi; do
  if [ "$(git -C $c rev-parse -q --verify refs/heads/production)" = "$tip" ]; then ok "production in $c/ equals production on the server"; else bad "production in $c/ differs from production on the server"; fi
done
check_end
