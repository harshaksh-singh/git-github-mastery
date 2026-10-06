#!/usr/bin/env bash
# Exercise 9.10 (Level 5): "rebased onto main, no functional change".
# Builds server.git and the clones you/, asha/ and ravi/ of the project "moderation-api".
# Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m09-vanished-guard
ex_begin m09-vanished-guard

ex_server
ex_clone ravi
cd ravi || exit 1
as ravi
mkdir -p api filters tests
printf 'from filters import abuse\n\ndef moderate(message):\n    score = abuse.score(message)\n    return {"allowed": score < 0.8}\n' > api/moderate.py
printf 'def score(message):\n    return 0.0\n' > filters/abuse.py
_c 'Add moderation endpoint'
quiet 'git push -u origin main'

quiet 'git switch -c feat/abuse-filter'
printf 'idiot\nmoron\n' > filters/words.txt
_c 'Add abuse word list'
printf 'WORDS = open("filters/words.txt").read().split()\n\ndef score(message):\n    hits = sum(w in message.lower() for w in WORDS)\n    return hits / len(message.split())\n' > filters/abuse.py
_c 'Score messages against the word list'
printf 'from filters import abuse\n\ndef moderate(message):\n    if not message.strip():\n        return {"allowed": False, "reason": "empty"}\n    score = abuse.score(message)\n    return {"allowed": score < 0.8}\n' > api/moderate.py
_c 'Reject empty messages before scoring'
printf 'from filters import abuse\n\ndef test_clean_message():\n    assert abuse.score("have a nice day") == 0.0\n' > tests/test_abuse.py
_c 'Add tests for the abuse filter'
quiet 'git push -u origin feat/abuse-filter'
cd "$LAB_DIR" || exit 1

# The reviewers clone while the pull request is open.
ex_clone asha
ex_clone you

# main moves: a size check in the same function.
cd asha || exit 1
as asha
printf 'from filters import abuse\n\ndef moderate(message):\n    if len(message) > 10000:\n        return {"allowed": False, "reason": "too long"}\n    score = abuse.score(message)\n    return {"allowed": score < 0.8}\n' > api/moderate.py
_c 'Reject messages longer than 10,000 characters'
quiet 'git push'
quiet 'git switch --detach'       # Asha goes on to review something else; her clone is not fetched again

# Ravi rebases. The third commit conflicts, and he "skips the conflict".
cd "$LAB_DIR/ravi" || exit 1
as ravi
quiet 'git fetch'
quiet 'git rebase origin/main'
quiet 'git rebase --skip'
quiet 'git push --force-with-lease'
ex_note rewritten_tip "$(git rev-parse HEAD)"

# You fetch, as you do every morning.
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git fetch'

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
