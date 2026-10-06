#!/usr/bin/env bash
# Gate 9 (Production debugging), hands-on part, variant B (retake): the project "cart-svc".
# Builds server.git and the clones you/ and ravi/. A bug that an earlier patch release fixed is
# back in production, and two confident explanations point in the wrong direction.
# Read SYMPTOMS.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/lib/gate-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin gates g9-b
gate_begin g9-b

gate_server
gate_clone you
cd you || exit 1
mkdir -p cart
printf 'def line_total(price, qty):\n    return price * qty\n\ndef cart_total(lines):\n    return sum(line_total(p, q) for p, q in lines)\n' > cart/total.py
_c 'Add line and cart totals'
printf 'pricing-lib==4.1\n' > requirements.txt
_c 'Add requirements'
quiet 'git tag -a v3.0.0 -m "cart-svc 3.0.0"'
quiet 'git push -u origin main'
quiet 'git branch release/3.0 v3.0.0'
quiet 'git push origin release/3.0 v3.0.0'
cd "$LAB_DIR" || exit 1

# Three weeks ago: Ravi fixes production on the release branch, tags 3.0.1, and prepares a
# port to main on a branch of its own. The pull request for the port was never merged.
gate_clone ravi
cd ravi || exit 1
as ravi
quiet 'git switch release/3.0'
printf 'def line_total(price, qty):\n    return price * max(qty, 0)\n\ndef cart_total(lines):\n    return sum(line_total(p, q) for p, q in lines)\n' > cart/total.py
_c 'Clamp negative quantities in the line total'
gate_note fix "$(git rev-parse HEAD)"
quiet 'git tag -a v3.0.1 -m "cart-svc 3.0.1"'
quiet 'git push origin release/3.0 v3.0.1'
quiet 'git switch -c port/clamp-quantities origin/main'
quiet 'git cherry-pick -x release/3.0'
quiet 'git push -u origin port/clamp-quantities'
gate_note v301 "$(git rev-parse 'v3.0.1^{commit}')"

# main moves on to 3.1 without the port.
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git mv cart/total.py cart/pricing.py'
_c 'Rename the total module to pricing'
printf 'pricing-lib==4.2\n' > requirements.txt
_c 'Bump pricing-lib to 4.2'
gate_note bump "$(git rev-parse HEAD)"
printf 'def apply_coupon(amount, percent):\n    return amount * (100 - percent) / 100\n' > cart/coupons.py
_c 'Add coupon support'
quiet 'git tag -a v3.1.0 -m "cart-svc 3.1.0"'
quiet 'git push origin main v3.1.0'
gate_note main "$(git rev-parse main)"
gate_note v310 "$(git rev-parse 'v3.1.0^{commit}')"
quiet 'git fetch'
# The on-call engineer's prepared fix, local only: a revert of the dependency bump.
quiet 'git switch -c oncall/revert-pricing-lib'
quiet "git revert --no-edit $(git rev-parse main~1)"
quiet 'git switch main'

gate_end
gate_ready
