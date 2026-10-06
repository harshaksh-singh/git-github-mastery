#!/usr/bin/env bash
# Exercise 10.10 (Level 5): "the fix is in the release" and "the fix was never backported".
# Builds server.git and the clones you/, asha/ and ravi/ of the project "prompt-router".
# Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m10-half-backport
ex_begin m10-half-backport

sel() { printf 'LIMIT = 8192\n\ndef select(tokens):\n    if tokens %s:\n        return "large"\n    return "small"\n' "$1" > router/select.py; }
ex_server
ex_clone asha
cd asha || exit 1
as asha
mkdir -p router
printf 'LIMIT = 8192\n\ndef select(tokens):\n    return "small"\n' > router/select.py
printf 'PRICES = {"small": 1, "large": 10}\n' > router/cost.py
printf '# Changelog\n\n## 2.3.0\n\n- First release of the 2.x line.\n' > CHANGELOG.md
_c 'Add prompt router'
quiet 'git push -u origin main'
quiet 'git switch -c release/2.x && git push -u origin release/2.x && git switch main'

# main: the fix for ROUTE-231, a feature, and a follow-up that completes the fix.
sel '> LIMIT'
quiet 'git add -A && git commit -m "Fix model selection for prompts over the context window" -m "Prompts longer than the context window of the small model were routed to it and failed. Route them to the large model." -m "Ticket: ROUTE-231"'
printf 'PRICES = {"small": 1, "large": 10}\n\ndef cheapest(models):\n    return min(models, key=PRICES.get)\n' > router/cost.py
_c 'Add cost-aware routing'
sel '>= LIMIT'
quiet 'git add -A && git commit -m "Route prompts of exactly the limit to the large model" -m "The small model needs room for at least one output token."'
quiet 'git push'
cd "$LAB_DIR" || exit 1

# Ravi backports "the fix" on the day the ticket was closed: the commit named in the ticket,
# without -x, and cuts 2.3.1.
ex_clone ravi
cd ravi || exit 1
as ravi
quiet 'git switch release/2.x'
fix=$(git log --format=%H -1 --grep='ROUTE-231' origin/main)
quiet "git cherry-pick $fix"
printf '# Changelog\n\n## 2.3.1\n\n- ROUTE-231: prompts over the context window are routed to the large model.\n\n## 2.3.0\n\n- First release of the 2.x line.\n' > CHANGELOG.md
_c 'Release 2.3.1'
quiet 'git push'
ex_note release_tip "$(git rev-parse HEAD)"

cd "$LAB_DIR" || exit 1
as you
ex_clone you
quiet 'git -C asha fetch'

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
