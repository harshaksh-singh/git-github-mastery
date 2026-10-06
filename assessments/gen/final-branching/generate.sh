#!/usr/bin/env bash
# Final test, practical lab "branching" (section 3): the project "driftwatch".
# Builds one repository in which two commits belong to no branch and the branch name you want is
# blocked. Read TASK.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/final-lib/final-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin final branching
final_begin branching

quiet 'git init driftwatch'
cd driftwatch || exit 1
mkdir -p drift
printf 'def psi(expected, actual, bins=10):\n    return sum((a - e) * log(a / e) for e, a in zip(expected, actual))\n' > drift/psi.py
_c 'Add the PSI metric'
printf 'def ks(expected, actual):\n    return max(abs(e - a) for e, a in zip(cdf(expected), cdf(actual)))\n' > drift/ks.py
_c 'Add the KS test'
quiet 'git switch -c fix'
printf 'def psi(expected, actual, bins=10):\n    eps = 1e-6\n    return sum((a - e) * log((a + eps) / (e + eps)) for e, a in zip(expected, actual))\n' > drift/psi.py
_c 'Avoid division by zero in empty bins'
final_note fix "$(git rev-parse HEAD)"
quiet 'git switch main && git merge fix'
printf 'WINDOW = 500\n\ndef window(rows):\n    return rows[-WINDOW:]\n' > drift/window.py
printf 'def report(scores):\n    return {name: round(value, 4) for name, value in scores.items()}\n' > drift/report.py
_c 'Add the drift report'
quiet 'git tag -a v0.3.0 -m "Release 0.3.0"'
final_note tag "$(git rev-parse refs/tags/v0.3.0)"
printf 'def alert(channel, scores):\n    return post(channel, report(scores))\n' > drift/alert.py
_c 'Add the Slack alert'
final_note main "$(git rev-parse HEAD)"

# Yesterday: the release is checked out to reproduce a customer problem, and fixed on the spot.
quiet 'git switch --detach v0.3.0'
printf 'import os\n\nWINDOW = int(os.environ.get("DRIFT_WINDOW", "500"))\n\ndef window(rows):\n    return rows[-WINDOW:]\n' > drift/window.py
_c 'Make the window size configurable'
printf 'import os\n\nWINDOW = int(os.environ.get("DRIFT_WINDOW", "500"))\nif WINDOW < 1:\n    raise ValueError("DRIFT_WINDOW must be positive")\n\ndef window(rows):\n    return rows[-WINDOW:]\n' > drift/window.py
_c 'Reject a window size below one'
final_note tip "$(git rev-parse HEAD)"
quiet 'git switch main'

final_end
final_ready
