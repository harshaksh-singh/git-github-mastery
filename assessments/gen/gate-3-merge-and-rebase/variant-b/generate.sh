#!/usr/bin/env bash
# Gate 3 (Merge and rebase), hands-on part, variant B (retake): the project "quota-svc".
# Builds server.git and asha/. In asha/ a cherry-pick of a range onto release/2.1 has stopped
# at a conflict, after picking a commit that the release must not get and skipping one it needs.
# Read SYMPTOMS.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/lib/gate-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin gates g3-b
gate_begin g3-b

gate_server
gate_clone asha
cd asha || exit 1
as asha
mkdir -p quota
printf 'def remaining(limit, used):\n    return limit - used\n' > quota/check.py
printf 'DEFAULT_LIMIT = 1000\n' > quota/limits.py
_c 'Add quota check'
printf 'WINDOW_S = 3600\n\ndef window_start(now):\n    return now - (now %% WINDOW_S)\n' > quota/window.py
printf 'def remaining_header(value):\n    return {"X-Quota-Remaining": str(int(value))}\n' > quota/headers.py
_c 'Add window and headers'
quiet 'git push -u origin main'
quiet 'git switch -c release/2.1'
printf 'WINDOW_S = 60\n\ndef window_start(now):\n    return now - (now %% WINDOW_S)\n' > quota/window.py
_c 'Use 60 second windows on 2.1'
quiet 'git push -u origin release/2.1'
gate_note release "$(git rev-parse release/2.1)"

quiet 'git switch main'
printf 'def remaining(limit, used):\n    return max(limit - used, 0)\n' > quota/check.py
_c 'Fix negative remaining quota'
f1=$(git rev-parse HEAD)
printf 'DEFAULT_LIMIT = 1000\nBURST = {"default": 50}\n' > quota/limits.py
_c 'Add per-tenant burst setting'
printf 'WINDOW_S = 3600\nDAY_S = 86400\n\ndef window_start(now):\n    return min(now - (now %% WINDOW_S), now - (now %% DAY_S) + DAY_S - WINDOW_S)\n' > quota/window.py
_c 'Fix window rollover at midnight UTC'
f2=$(git rev-parse HEAD)
printf 'def remaining_header(value):\n    return {"X-Quota-Remaining": str(max(int(round(value)), 0))}\n' > quota/headers.py
_c 'Fix rounding of the quota header'
f3=$(git rev-parse HEAD)
quiet 'git push origin main'
gate_note main "$f3"
gate_note f1 "$f1"; gate_note f2 "$f2"; gate_note f3 "$f3"

# The backport: a range whose left end is the first commit that was wanted.
quiet 'git switch release/2.1'
quiet "git cherry-pick -x $f1..$f3"

gate_end
gate_ready
