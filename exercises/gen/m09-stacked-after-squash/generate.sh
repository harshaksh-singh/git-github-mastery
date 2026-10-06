#!/usr/bin/env bash
# Exercise 9.9 (Level 4): the morning rebase that replays somebody else's commits.
# Builds the repository policy-engine/ in the middle of a stopped rebase. Read SYMPTOMS.md, not
# this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m09-stacked-after-squash
ex_begin m09-stacked-after-squash

quiet 'git init policy-engine'
cd policy-engine || exit 1
mkdir -p rules
printf 'def check(text, rules):\n    return [r.name for r in rules if r.match(text)]\n' > engine.py
_c 'Add policy engine'

# Asha's branch, three commits.
quiet 'git switch -c feat/pii-rules'
as asha
printf 'import re\n\ndef find_emails(text):\n    return []\n' > rules/pii.py
_c 'Add PII rule skeleton'
printf 'import re\n\ndef find_emails(text):\n    return re.findall(r"[\\w.]+@[\\w.]+", text)\n' > rules/pii.py
_c 'Detect email addresses'
printf 'import re\n\ndef find_emails(text):\n    return re.findall(r"[\\w.]+@[\\w.]+", text)\n\ndef find_phones(text):\n    return re.findall(r"\\+?[0-9][0-9 -]{7,}", text)\n' > rules/pii.py
_c 'Detect phone numbers'

# Your branch, stacked on hers, two commits.
quiet 'git switch -c feat/pii-redaction'
as you
printf 'def redact(text, spans):\n    for s in spans:\n        text = text.replace(s, "[REDACTED]")\n    return text\n' > redact.py
_c 'Add redaction of matched spans'
printf 'from redact import redact\nfrom rules.pii import find_emails\n\ndef log(line):\n    print(redact(line, find_emails(line)))\n' > audit_log.py
_c 'Redact email addresses in the audit log'
ex_note redact_blob "$(git rev-parse HEAD:redact.py)"
ex_note log_blob "$(git rev-parse HEAD:audit_log.py)"

# Her pull request is squash-merged with one change asked for in review, and her branch is deleted.
quiet 'git switch main'
as asha
quiet 'git merge --squash feat/pii-rules'
printf 'import re\n\nEMAIL = re.compile(r"[\\w.]+@[\\w.]+")\n\ndef find_emails(text):\n    return EMAIL.findall(text)\n\ndef find_phones(text):\n    return re.findall(r"\\+?[0-9][0-9 -]{7,}", text)\n' > rules/pii.py
quiet 'git add rules/pii.py && git commit -m "Add PII rules (#12)"'
quiet 'git branch -D feat/pii-rules'
ex_note main_tip "$(git rev-parse HEAD)"

# You, this morning.
as you
quiet 'git switch feat/pii-redaction'
quiet 'git rebase main'

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
