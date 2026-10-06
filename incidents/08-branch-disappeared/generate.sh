#!/usr/bin/env bash
# Incident 8: a branch appears to have disappeared.
# Builds server.git and the clones you/, asha/ and ravi/ of the project "prompt-registry".
# ravi/ plays the part of GitHub's merge button: a squash merge followed by the automatic
# deletion of the head branch. Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/incidents/lib/incident-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin incidents 08-branch-disappeared
inc_begin

inc_server
inc_clone you
cd you || exit 1
mkdir -p registry
printf 'def save(name, text):\n    db.put(name, text)\n\ndef load(name):\n    return db.get(name)\n' > registry/store.py
_c 'Add prompt store'
printf '# prompt-registry\n\nStores the prompts of our LLM applications.\n' > README.md
_c 'Add README'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1
inc_clone asha
inc_clone ravi

cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git config set fetch.prune true'
quiet 'git switch -c feature/prompt-versioning'
printf 'def save(name, text):\n    version = db.count(name) + 1\n    db.put((name, version), text)\n    return version\n\ndef load(name):\n    return db.get(name)\n' > registry/store.py
_c 'Store every save as a new version'
printf 'def save(name, text):\n    version = db.count(name) + 1\n    db.put((name, version), text)\n    return version\n\ndef load(name, version=None):\n    return db.get((name, version or db.count(name)))\n' > registry/store.py
_c 'Load a prompt by version'
printf 'def history(name):\n    return [db.get((name, v)) for v in range(1, db.count(name) + 1)]\n' > registry/history.py
_c 'Add version history'
quiet 'git push -u origin feature/prompt-versioning'

# The pull request is squash-merged and the head branch is deleted on the server.
cd "$LAB_DIR/ravi" || exit 1
as ravi
quiet 'git fetch'
quiet 'git merge --squash origin/feature/prompt-versioning'
quiet 'git commit --author="Asha Rao <asha@example.com>" -m "Add prompt versioning (#42)"'
quiet 'git push'
quiet 'git push origin --delete feature/prompt-versioning'

# Asha, unaware, adds one more commit, then tidies up when she sees the branch is "gone".
cd "$LAB_DIR/asha" || exit 1
as asha
printf 'import string\n\ndef variables(text):\n    return {f for _, f, _, _ in string.Formatter().parse(text) if f}\n\ndef validate(text, allowed):\n    unknown = variables(text) - set(allowed)\n    if unknown:\n        raise ValueError(f"unknown variables: {sorted(unknown)}")\n' > registry/validate.py
_c 'Validate prompt variables before save'
quiet 'git fetch'
quiet 'git switch main'
quiet 'git pull'
quiet 'git branch -D feature/prompt-versioning'

inc_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Incident ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
