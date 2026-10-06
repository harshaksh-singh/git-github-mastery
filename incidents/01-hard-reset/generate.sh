#!/usr/bin/env bash
# Incident 1: a developer runs "git reset --hard" by accident.
# Builds server.git and the clones you/ and ravi/ of the project "triage-bot". The damage is in
# ravi/. Read SYMPTOMS.md, not this file, before you start: the script is the answer to
# "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/incidents/lib/incident-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin incidents 01-hard-reset
inc_begin

inc_server
inc_clone you
cd you || exit 1
mkdir -p triage rules
printf 'def classify(ticket):\n    return model.predict(ticket.subject + "\\n" + ticket.body)\n' > triage/classify.py
printf 'default_queue: general\n' > rules/routing.yaml
_c 'Add ticket classifier'
printf '# triage-bot\n\nRoutes support tickets to a queue.\n' > README.md
_c 'Add README'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1

inc_clone ravi
cd ravi || exit 1
as ravi
quiet 'git switch -c feature/escalation-rules'
printf 'def should_escalate(ticket, label):\n    return label == "outage" or ticket.customer_tier == "enterprise"\n' > triage/escalate.py
_c 'Add escalation predicate'
printf 'default_queue: general\nescalation_queue: oncall\n' > rules/routing.yaml
_c 'Route escalated tickets to the on-call queue'
printf 'def should_escalate(ticket, label):\n    if ticket.is_spam:\n        return False\n    return label == "outage" or ticket.customer_tier == "enterprise"\n' > triage/escalate.py
_c 'Never escalate spam'

# Meanwhile main moves on the server.
cd "$LAB_DIR/you" || exit 1
as you
printf '# triage-bot\n\nRoutes support tickets to a queue.\n\nRun the tests with `python3 -m unittest`.\n' > README.md
_c 'Document how to run the tests'
quiet 'git push'

# Ravi: one file staged and never committed, one edit never staged, then the accident.
cd "$LAB_DIR/ravi" || exit 1
as ravi
printf 'outage: 1\nbilling: 2\nhow-to: 3\n' > rules/priority.yaml
quiet 'git add rules/priority.yaml'
printf 'default_queue: general\nescalation_queue: oncall\nescalation_sla_minutes: 15\n' > rules/routing.yaml
quiet 'git fetch'
quiet 'git reset --hard origin/main'
# He kept working before he noticed.
printf '# triage-bot\n\nRoutes support tickets to a queue and escalates outages.\n\nRun the tests with `python3 -m unittest`.\n' > README.md
_c 'Mention escalation in the README'

inc_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Incident ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
