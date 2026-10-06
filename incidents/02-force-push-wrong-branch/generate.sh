#!/usr/bin/env bash
# Incident 2: a developer force-pushes to the wrong branch.
# Builds server.git and the clones you/, asha/ and ravi/ of the project "ingest-pipeline".
# Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/incidents/lib/incident-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin incidents 02-force-push-wrong-branch
inc_begin

inc_server
inc_clone you
cd you || exit 1
mkdir -p ingest
printf 'def load(path):\n    return [parse(line) for line in open(path)]\n' > ingest/load.py
printf 'batch_size: 500\n' > ingest/config.yaml
_c 'Add loader'
printf 'def validate(rows):\n    return [r for r in rows if r.get("id")]\n' > ingest/validate.py
_c 'Add row validation'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1
inc_clone asha
inc_clone ravi

# Asha starts a feature branch from origin/main. Her configuration carries an old setting.
cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git config set push.default upstream'
quiet 'git switch -c feature/dedupe origin/main'
printf 'def dedupe(rows):\n    seen = set()\n    return [r for r in rows if not (r["id"] in seen or seen.add(r["id"]))]\n' > ingest/dedupe.py
_c 'WIP dedupe by id'
printf 'batch_size: 500\ndedupe: true\n' > ingest/config.yaml
_c 'WIP config flag, tests still red'

# Two reviewed changes land on main.
cd "$LAB_DIR/ravi" || exit 1
as ravi
printf 'def validate(rows):\n    return [r for r in rows if r.get("id") and r.get("ts")]\n' > ingest/validate.py
_c 'Reject rows without a timestamp'
quiet 'git push'
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git pull'
printf 'def load(path):\n    with open(path) as f:\n        return [parse(line) for line in f]\n' > ingest/load.py
_c 'Close the input file after loading'
quiet 'git push'

# Asha tidies her branch and publishes it. The push goes where push.default sends it.
cd "$LAB_DIR/asha" || exit 1
as asha
printf 'def dedupe(rows):\n    seen = set()\n    out = []\n    for r in rows:\n        if r["id"] not in seen:\n            seen.add(r["id"])\n            out.append(r)\n    return out\n' > ingest/dedupe.py
quiet 'git commit -a --amend -m "WIP config flag and readable dedupe, tests still red"'
quiet 'git push --force'

inc_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Incident ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
