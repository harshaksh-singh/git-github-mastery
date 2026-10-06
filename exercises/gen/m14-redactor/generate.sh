#!/usr/bin/env bash
# Exercise 14.9 (Level 4): two fixes made in a linked worktree that no longer exists.
# Builds the project "redactor" in redactor/. Read SYMPTOMS.md, not this file: the script is the
# answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m14-redactor

quiet 'git init redactor'
cd redactor || exit 1
put redactor/patterns.py <<'F'
"""Patterns for personal data that must not reach the model or the logs."""

import re

EMAIL = re.compile(r"[\w.+-]+@[\w-]+\.[\w.]+")
PHONE = re.compile(r"\+?\d[\d -]{8,}\d")
F
put redactor/scrub.py <<'F'
from redactor.patterns import EMAIL, PHONE


def scrub(text):
    return PHONE.sub("[phone]", EMAIL.sub("[email]", text))
F
_c 'Add email and phone redaction'
printf '# redactor\n\nRemoves personal data from prompts and logs.\n' > README.md
_c 'Add README'
quiet "git tag -a v2.1.0 -m 'redactor 2.1.0'"
put redactor/audit.py <<'F'
def audit(before, after):
    return {"changed": before != after, "length": len(after)}
F
_c 'Add redaction audit record'
quiet 'git switch -c feature/names'
printf 'TITLES = ("Mr", "Ms", "Dr")\n' > redactor/names.py
_c 'Start name detection'

# Yesterday: a hotfix on the released version, in a second working tree, on a detached HEAD.
quiet 'git worktree add --detach ../redactor-hotfix v2.1.0'
cd ../redactor-hotfix || exit 1
sed -e 's/{8,}/{7,}/' redactor/patterns.py > p.tmp && mv p.tmp redactor/patterns.py
_c 'Redact ten-digit phone numbers'
printf 'IBAN = re.compile(r"[A-Z]{2}\\d{2}[A-Z0-9]{11,30}")\n' >> redactor/patterns.py
sed -e 's/import EMAIL, PHONE/import EMAIL, IBAN, PHONE/' -e 's/return PHONE/return IBAN.sub("[iban]", PHONE/' -e 's/text))$/text)))/' redactor/scrub.py > s.tmp && mv s.tmp redactor/scrub.py
_c 'Redact IBANs'
printf 'CARD = re.compile(r"\\d{4}( ?\\d{4}){3}")\n' >> redactor/patterns.py      # never committed
# Today: the worktree is in the way.
cd ../redactor || exit 1
quiet 'git worktree remove --force ../redactor-hotfix'

ex_end redactor
