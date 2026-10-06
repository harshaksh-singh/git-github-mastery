#!/usr/bin/env bash
# Incident 4: the history of the production branch is rewritten.
# Builds server.git and the clones you/, asha/ and ravi/ of the project "billing-api".
# Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/incidents/lib/incident-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin incidents 04-production-history-rewritten
inc_begin

inc_server
inc_clone you
cd you || exit 1
mkdir -p billing
printf '# billing-api\n\nThe branch `production` is what runs. Deployments are tagged `deploy-<date>`.\n' > README.md
_c 'Add README'
quiet 'git push -u origin main'
quiet 'git switch -c production'
printf 'def total(lines):\n    return sum(l.qty * l.unit_price for l in lines)\n' > billing/invoice.py
_c 'Add invoice totals'
printf 'def tax(amount, rate):\n    return amount * rate\n' > billing/tax.py
_c 'Add tax calculation'
printf 'def tax(amount, rate):\n    return round(amount * rate, 2)\n' > billing/tax.py
_c 'Round tax to two decimals'
printf 'def money(amount, currency):\n    return f"{currency} {amount:,.2f}"\n' > billing/format.py
_c 'Add currency formatting'
printf 'def log_failure(invoice, exc):\n    logger.error("invoice %%s failed: %%s", invoice.id, exc)\n' > billing/log.py
_c 'Log the invoice id on failure'
quiet 'git tag -a deploy-2026-09-07 -m "Deployed to production by the release job"'
quiet 'git push -u origin production deploy-2026-09-07'
quiet 'git switch main'
cd "$LAB_DIR" || exit 1
inc_clone asha
quiet 'git -C asha switch production'
inc_clone ravi
quiet 'git -C ravi switch production'

# Ravi "tidies" production: one commit dropped, three folded into one, then a plain force push.
cd "$LAB_DIR/ravi" || exit 1
as ravi
tick
GIT_SEQUENCE_EDITOR="sed -i.bak -e '2d' -e '3,4s/^pick/fixup/'" git rebase -i production~4 > /dev/null 2>&1
quiet 'git commit --amend -m "Tax calculation, formatting and logging"'
quiet 'git push --force origin production'

# Asha is told to "just reset to the server", does so, and ships a new change on top.
cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git fetch'
quiet 'git reset --hard origin/production'
printf 'def footer(invoice):\n    return f"Invoice {invoice.number} - page {invoice.page}"\n' > billing/pdf.py
_c 'Add invoice PDF footer'
quiet 'git push'

inc_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Incident ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
