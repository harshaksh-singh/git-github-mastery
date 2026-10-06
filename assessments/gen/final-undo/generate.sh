#!/usr/bin/env bash
# Final test, practical lab "undo" (section 6): the project "routeplan".
# Builds server.git and the clones you/ and asha/. You amended a commit that was already
# published, and a colleague has built on the original. Read TASK.md, not this file, first.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/final-lib/final-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin final undo
final_begin undo

final_server
final_clone you
cd you || exit 1
printf 'highway: 1.0\narterial: 1.2\nlocal: 1.4\n' > weights.yaml
printf 'def cost(edge, weights):\n    return edge.length * weights[edge.kind]\n' > planner.py
_c 'Add route weights'
printf 'highway: 1.0\ntool: 1.5\narterial: 1.2\nlocal: 1.4\n' > weights.yaml
printf 'def cost(edge, weights):\n    base = edge.length * weights[edge.kind]\n    return base * weights["toll"] if edge.toll else base\n' > planner.py
_c 'Add a toll penalty'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1

# Asha pulls and builds on the published commit.
final_clone asha
cd asha || exit 1
as asha
printf 'highway: 1.0\ntool: 1.5\narterial: 1.2\nlocal: 1.4\nferry: 3.0\n' > weights.yaml
_c 'Add a ferry penalty'
quiet 'git push'
final_note asha "$(git rev-parse HEAD)"
cd "$LAB_DIR/you" || exit 1

# You notice the misspelled key and "quickly fix the commit".
as you
printf 'highway: 1.0\ntoll: 1.5\narterial: 1.2\nlocal: 1.4\n' > weights.yaml
quiet 'git commit -a --amend --no-edit'

final_end
final_ready
