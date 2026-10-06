#!/usr/bin/env bash
# Gate 9 (Production debugging), hands-on part, variant A: the project "storefront-api".
# Builds server.git and the clones you/, asha/ and ravi/. A release branch contains code that
# was never meant to be released, and the people involved explain it in three different ways.
# Read SYMPTOMS.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/lib/gate-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin gates g9-a
gate_begin g9-a

gate_server
gate_clone you
cd you || exit 1
mkdir -p checkout docs
printf 'def total(items):\n    return sum(i.price * i.qty for i in items)\n' > checkout/total.py
_c 'Add checkout total'
printf 'def round_amount(x):\n    return round(x, 2)\n' > checkout/rounding.py
_c 'Add rounding helper'
printf '2.2.0\n' > VERSION
_c 'Release 2.2.0'
quiet 'git tag -a v2.2.0 -m "storefront-api 2.2.0"'
quiet 'git push -u origin main'
quiet 'git switch -c release/2.2'
printf '2.2.1\n' > VERSION
_c 'Release 2.2.1'
quiet 'git tag -a v2.2.1 -m "storefront-api 2.2.1"'
quiet 'git push -u origin release/2.2'
quiet 'git push origin v2.2.0 v2.2.1'
gate_note v221 "$(git rev-parse 'v2.2.1^{commit}')"

# main moves on: unreleased work for 2.3, and one fix that 2.2 needs as well.
quiet 'git switch main'
printf 'WALLET_ENABLED = False\n\ndef wallet_balance(user):\n    return user.wallet\n' > checkout/wallet.py
_c 'Add wallet payments behind a flag'
printf 'from checkout.wallet import wallet_balance\n\ndef total(items, user=None):\n    amount = sum(i.price * i.qty for i in items)\n    return amount - (wallet_balance(user) if user else 0)\n' > checkout/total.py
_c 'Apply the wallet balance in the total'
printf 'from decimal import Decimal, ROUND_HALF_UP\n\ndef round_amount(x):\n    return float(Decimal(str(x)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))\n' > checkout/rounding.py
_c 'Fix currency rounding for half cents'
gate_note fix "$(git rev-parse HEAD)"
gate_note fixblob "$(git rev-parse HEAD:checkout/rounding.py)"
printf '# Changelog\n\n## 2.3 (unreleased)\n\n- Wallet payments\n' > docs/CHANGELOG.md
_c 'Start the 2.3 changelog'
quiet 'git push origin main'
gate_note main "$(git rev-parse main)"
cd "$LAB_DIR" || exit 1

# Asha needs the rounding fix on the release branch, and merges main to get it.
gate_clone asha
cd asha || exit 1
as asha
quiet 'git switch release/2.2'
quiet 'git merge origin/main'
gate_note merge "$(git rev-parse HEAD)"
quiet 'git push origin release/2.2'
cd "$LAB_DIR" || exit 1

# Ravi adds a release-only commit on top and pushes.
gate_clone ravi
cd ravi || exit 1
as ravi
quiet 'git switch release/2.2'
printf 'FROM python:3.13-slim@sha256:dummy-digest-for-the-exercise\nCOPY . /app\n' > Dockerfile
_c 'Pin the base image for 2.2.2'
quiet 'git push origin release/2.2'
gate_note tip "$(git rev-parse HEAD)"

# Your clone is up to date with the server, on main.
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git fetch'

gate_end
gate_ready
