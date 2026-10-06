#!/usr/bin/env bash
# Final test, practical lab "incident" (section 15): the project "tokenbudget".
# Builds server.git and the clones you/ and ravi/. Release 1.5.0 ships a bug that release 1.4.1
# fixed. Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/final-lib/final-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin final incident
final_begin incident

final_server
final_clone you
cd you || exit 1
printf 'def allowed(used, limit):\n    return used < limit\n\n\ndef remaining(used, limit):\n    return max(limit - used, 0)\n' > budget.py
printf 'default_limit: 100000\n' > limits.yaml
_c 'Add the token budget'
printf 'def usage(events):\n    return sum(e.tokens for e in events)\n' > usage.py
_c 'Add usage accounting'
quiet 'git tag -a v1.4.0 -m "Release 1.4.0"'
quiet 'git branch release/1.4'
quiet 'git push -u origin main release/1.4 v1.4.0'
printf 'default_limit: 100000\nteams:\n  search: 250000\n  support: 150000\n' > limits.yaml
_c 'Add per-team budgets'
quiet 'git push'
cd "$LAB_DIR" || exit 1

# Ravi fixes a customer bug on the release branch and ships 1.4.1.
final_clone ravi
cd ravi || exit 1
as ravi
quiet 'git switch release/1.4'
printf 'def allowed(used, limit):\n    return used <= limit\n\n\ndef remaining(used, limit):\n    return max(limit - used, 0)\n' > budget.py
_c 'Allow a request that exactly reaches the budget'
final_note fix "$(git rev-parse HEAD)"
quiet 'git tag -a v1.4.1 -m "Release 1.4.1"'
quiet 'git push origin release/1.4 v1.4.1'
final_note release "$(git rev-parse HEAD)"
final_note v141 "$(git rev-parse refs/tags/v1.4.1)"
cd "$LAB_DIR/you" || exit 1

# main moves on and 1.5.0 is released from it.
as you
printf 'def alert(team, used, limit):\n    if used >= 0.9 * limit:\n        notify(team, used, limit)\n' > alerts.py
_c 'Add budget alerts'
printf 'def usage(events, team=None):\n    return sum(e.tokens for e in events if team in (None, e.team))\n' > usage.py
_c 'Account usage per team'
quiet 'git tag -a v1.5.0 -m "Release 1.5.0"'
quiet 'git push origin main v1.5.0'
final_note main "$(git rev-parse HEAD)"
final_note v150 "$(git rev-parse refs/tags/v1.5.0)"
quiet 'git fetch'

final_end
final_ready
