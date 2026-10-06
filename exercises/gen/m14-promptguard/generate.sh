#!/usr/bin/env bash
# Practice repositories for the Module 14 exercises 14.1 to 14.8 (worktrees, attributes, hooks,
# stash internals, rerere). Each exercise has its own directory ex-14-N/ with a piece of the
# project "promptguard" (a filter that screens user prompts before they reach the model).
# Do the exercises before you read this file: the script is the answer to several of them.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m14-promptguard

seed() {
  put guard/rules.py <<'F'
"""Rules that reject a prompt before it reaches the model."""

MAX_CHARS = 8000
BLOCKED = ["ignore previous instructions", "reveal your system prompt"]


def allowed(prompt):
    text = prompt.lower()
    return len(prompt) <= MAX_CHARS and not any(phrase in text for phrase in BLOCKED)
F
  _c 'Add prompt rules'
  printf '# promptguard\n\nScreens user prompts before they reach the model.\n' > README.md
  _c 'Add README'
}

# ---------------------------------------------------------------- 14.1 a second working tree
quiet 'git init ex-14-1'; cd ex-14-1 || exit 1
seed
quiet 'git switch -c feature/unicode'
printf 'import unicodedata\n\n\ndef normalize(prompt):\n    return unicodedata.normalize("NFKC", prompt)\n' > guard/normalize.py
_c 'Add Unicode normalization'
printf '\n\ndef strip_zero_width(prompt):\n    return prompt.replace("\\u200b", "")\n' >> guard/normalize.py
printf 'half-finished notes\n' > NOTES.txt
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 14.2 attributes
quiet 'git init ex-14-2'; cd ex-14-2 || exit 1
seed
put notebooks/eval.ipynb <<'F'
{"cells": [{"cell_type": "code", "source": ["blocked = 41"], "outputs": []}], "nbformat": 4}
F
put data/golden.jsonl <<'F'
{"prompt": "hello", "allowed": true}
F
printf '# Internal notes\n\nRed-team findings. Not for the release tarball.\n' > docs-internal.md
_c 'Add notebook, golden data and internal notes'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 14.3 a pre-commit hook (you write it)
quiet 'git init ex-14-3'; cd ex-14-3 || exit 1
seed
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 14.4 the shape of a stash entry
quiet 'git init ex-14-4'; cd ex-14-4 || exit 1
seed
printf 'MAX_TURNS = 40\n' > guard/limits.py
_c 'Add turn limit'
printf 'MAX_TURNS = 60\n' > guard/limits.py
quiet 'git add guard/limits.py'
printf '\nSee `guard/rules.py` for the rules.\n' >> README.md
printf 'scratch\n' > todo.txt
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 14.5 a changelog that always conflicts
quiet 'git init ex-14-5'; cd ex-14-5 || exit 1
seed
printf '# Changelog\n\n- Add prompt rules\n' > CHANGELOG.md
_c 'Add changelog'
quiet 'git switch -c feat/length-limit'
sed -e 's/MAX_CHARS = 8000/MAX_CHARS = 12000/' guard/rules.py > r.tmp && mv r.tmp guard/rules.py
printf -- '- Raise the length limit to 12000 characters\n' >> CHANGELOG.md
_c 'Raise the length limit'
quiet 'git switch -c feat/audit-log main'
printf 'def audit(prompt, verdict):\n    print(verdict, len(prompt))\n' > guard/audit.py
printf -- '- Log every verdict\n' >> CHANGELOG.md
_c 'Log every verdict'
quiet 'git switch main'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 14.6 which hooks run
quiet 'git init ex-14-6'; cd ex-14-6 || exit 1
seed
quiet 'git switch -c topic'
printf 'MAX_TURNS = 40\n' > guard/limits.py
_c 'Add turn limit'
quiet 'git switch main'
printf '\nRules live in `guard/rules.py`.\n' >> README.md
_c 'Point to the rules'
for h in pre-commit prepare-commit-msg commit-msg post-commit pre-merge-commit post-merge pre-rebase post-rewrite post-checkout; do
  printf '#!/bin/sh\necho "[hook] %s"\n' "$h" > ".git/hooks/$h"
  chmod +x ".git/hooks/$h"
done
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 14.7 a hook that works on one machine
mkdir ex-14-7 && cd ex-14-7 || exit 1
ex_server; ex_clone you; cd you || exit 1
seed
put .githooks/commit-msg <<'F'
#!/bin/sh
# Every commit message starts with a ticket, for example "PG-123: ...".
head -1 "$1" | grep -Eq '^PG-[0-9]+: ' && exit 0
echo "commit-msg: the subject must start with a ticket such as PG-123: " >&2
exit 1
F
quiet 'git add .githooks && git commit -m "PG-7: Add commit-msg hook for ticket numbers"'
quiet 'git push -u origin main'
quiet 'git config set core.hooksPath .githooks'
chmod +x .githooks/commit-msg
cd .. || exit 1
ex_clone asha; cd asha || exit 1
as asha
quiet 'git config set core.hooksPath .githooks'
printf '\nNo ticket here.\n' >> README.md
quiet 'git commit -am "fix readme"'
quiet 'git push'
as you
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 14.8 a resolution you never typed
quiet 'git init ex-14-8'; cd ex-14-8 || exit 1
quiet 'git config set rerere.enabled true && git config set maintenance.rerere-gc.auto 0'
put guard/client.yaml <<'F'
model: guard-small
timeout_seconds: 10
retries: 1
F
_c 'Add classifier client settings'
quiet 'git switch -c feat/timeouts'
put guard/client.yaml <<'F'
model: guard-small
timeout_seconds: 30
retries: 1
F
_c 'Raise the classifier timeout to 30 seconds'
quiet 'git switch main'
put guard/client.yaml <<'F'
model: guard-small
timeout_seconds: 5
retries: 3
F
_c 'Fail fast and retry three times'
# A first attempt at the merge, resolved in a hurry and then thrown away.
quiet 'git merge feat/timeouts'
put guard/client.yaml <<'F'
model: guard-small
timeout_seconds: 5
retries: 3
F
quiet 'git add guard/client.yaml && git commit --no-edit'
quiet 'git reset --hard HEAD~1'
cd "$LAB_DIR" || exit 1

unset -f seed
ex_end
