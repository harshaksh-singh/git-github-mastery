#!/usr/bin/env bash
# Exercise 12.11 (Level 5): a branch deleted everywhere its owner could reach, followed by a
# "cleanup" that removed the local safety net. Builds server.git and the clones you/, asha/ and
# ravi/ of the project "feedbackloop". Read SYMPTOMS.md, not this file: the script is the answer.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m12-feedbackloop

ex_server
ex_clone you
cd you || exit 1
put feedbackloop/ingest.py <<'F'
"""Reads user feedback events (thumbs up, thumbs down, free text)."""


def ingest(events):
    return [e for e in events if e.get("conversation_id")]
F
_c 'Add feedback ingestion'
printf '# feedbackloop\n\nTurns user feedback into evaluation data.\n' > README.md
_c 'Add README'
quiet 'git push -u origin main'
quiet 'git config set fetch.prune true'
cd "$LAB_DIR" || exit 1
ex_clone asha
ex_clone ravi

B=feature/dedupe-feedback
cd ravi || exit 1
as ravi
quiet "git switch -c $B"
put feedbackloop/fingerprint.py <<'F'
import hashlib


def fingerprint(event):
    raw = "%s|%s|%s" % (event["conversation_id"], event["turn"], event["rating"])
    return hashlib.sha1(raw.encode("utf-8")).hexdigest()
F
_c 'Add feedback fingerprint'
put feedbackloop/dedupe.py <<'F'
from feedbackloop.fingerprint import fingerprint


def dedupe(events):
    seen, kept = set(), []
    for event in events:
        mark = fingerprint(event)
        if mark not in seen:
            seen.add(mark)
            kept.append(event)
    return kept
F
_c 'Drop duplicate feedback by fingerprint'
quiet "git push -u origin $B"

cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git fetch'

cd "$LAB_DIR/ravi" || exit 1
as ravi
put feedbackloop/dedupe.py <<'F'
from feedbackloop.fingerprint import fingerprint


def dedupe(events):
    newest = {}
    for event in events:
        mark = fingerprint(event)
        if mark not in newest or event["ts"] > newest[mark]["ts"]:
            newest[mark] = event
    return sorted(newest.values(), key=lambda e: e["ts"])
F
_c 'Keep the newest of two duplicates'
put feedbackloop/dedupe.py <<'F'
from feedbackloop.fingerprint import fingerprint


def dedupe(events):
    newest = {}
    for event in events:
        mark = fingerprint(event)
        if mark not in newest or event["ts"] > newest[mark]["ts"]:
            newest[mark] = event
    kept = sorted(newest.values(), key=lambda e: e["ts"])
    return kept, len(events) - len(kept)
F
_c 'Count dropped duplicates'
quiet 'git push'

cd "$LAB_DIR/you" || exit 1
as you
quiet 'git fetch'

cd "$LAB_DIR/ravi" || exit 1
as ravi
put feedbackloop/retention.py <<'F'
RETENTION_DAYS = 90


def within_retention(event, now):
    return now - event["ts"] <= RETENTION_DAYS * 86400
F
_c 'Skip feedback older than the retention window'
mkdir -p ../asha/inbox
quiet 'git format-patch -1 -o ../asha/inbox'

# The accident: Ravi believes the branch was merged.
quiet 'git switch main'
quiet "git push origin --delete $B"
quiet "git branch -D $B"
quiet 'git reflog expire --expire=now --all'
quiet 'git gc --prune=now'

ex_end
