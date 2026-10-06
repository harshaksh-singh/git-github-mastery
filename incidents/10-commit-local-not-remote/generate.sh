#!/usr/bin/env bash
# Incident 10: a commit exists locally but not remotely.
# Builds server.git (the team repository), ravi-fork.git (a fork Ravi made before he joined the
# team) and the clones you/, asha/ and ravi/ of the project "eval-dashboard".
# Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/incidents/lib/incident-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin incidents 10-commit-local-not-remote
inc_begin

inc_server
inc_clone you
cd you || exit 1
mkdir -p dashboard
printf 'def aggregate(scores):\n    return sum(scores) / len(scores)\n' > dashboard/aggregate.py
_c 'Add score aggregation'
printf 'def panel(run):\n    return {"accuracy": aggregate(run.scores)}\n' > dashboard/panels.py
_c 'Add accuracy panel'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1
inc_clone asha

# Ravi's fork, and his clone of the fork with the team repository as a second remote.
quiet 'git clone --bare server.git ravi-fork.git'
quiet 'git -C ravi-fork.git remote remove origin'
inc_clone ravi ravi-fork.git
quiet 'git -C ravi remote add upstream ../server.git'
quiet 'git -C ravi fetch upstream'

# The team repository moves on.
cd "$LAB_DIR/you" || exit 1
printf 'def panel(run):\n    return {"accuracy": aggregate(run.scores), "p95_latency_ms": percentile(run.latencies, 95)}\n' > dashboard/panels.py
_c 'Show p95 latency on the dashboard'
quiet 'git push'

# Ravi fixes a bug, commits on main and pushes.
cd "$LAB_DIR/ravi" || exit 1
as ravi
printf 'import math\n\ndef aggregate(scores):\n    scores = [s for s in scores if not math.isnan(s)]\n    return sum(scores) / len(scores) if scores else float("nan")\n' > dashboard/aggregate.py
_c 'Guard against NaN in score aggregation'
quiet 'git push'

inc_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Incident ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
