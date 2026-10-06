#!/usr/bin/env bash
# Gate 4 (Recovery), hands-on part, variant B (retake): the project "latency-probe".
# Builds server.git and asha/. A regression has to be traced to its commit, and a branch that
# was fetched from a colleague's machine and deleted without ever being checked out has to be found.
# Read SYMPTOMS.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/lib/gate-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin gates g4-b
gate_begin g4-b

gate_server
gate_clone asha
cd asha || exit 1
as asha
mkdir -p probe tools
printf 'TIMEOUT_MS = 250\n' > probe/settings.py
printf 'RETRY_MULTIPLIER = 1\n' > probe/retry.py
_c 'Add probe settings and retry policy'
cat > tools/p95.sh <<'SH'
#!/bin/sh
# Prints the effective timeout in milliseconds: the base timeout times the retry multiplier.
base=$(cat probe/config.py probe/settings.py 2>/dev/null | sed -n 's/^TIMEOUT_MS = \([0-9]*\).*/\1/p' | head -1)
mult=$(sed -n 's/^RETRY_MULTIPLIER = \([0-9]*\).*/\1/p' probe/retry.py)
echo $((base * mult))
SH
_c 'Add effective-timeout script'
printf 'P95_ALERT_MS = 400\n' > probe/alerts.py
_c 'Add alert thresholds'
quiet 'git tag -a v1.0.0 -m "latency-probe 1.0.0"'
quiet 'git mv probe/settings.py probe/config.py'
_c 'Rename settings module to config'
printf 'RETRY_MULTIPLIER = 1\nJITTER_MS = 20\n' > probe/retry.py
_c 'Add jitter to retries'
printf '# Retry policy\nJITTER_MS = 20\nRETRY_MULTIPLIER = 10\n' > probe/retry.py
_c 'Tidy retry module'
gate_note culprit "$(git rev-parse HEAD)"
printf '# Probe configuration\n\nTIMEOUT_MS = 250  # milliseconds\n' > probe/config.py
_c 'Reformat config with the new formatter'
printf 'P95_ALERT_MS = 400\nP99_ALERT_MS = 900\n' > probe/alerts.py
_c 'Add p99 alert'
printf '# latency-probe\n\nMeasures request latency.\n' > README.md
_c 'Document the probe'
printf '# latency-probe\n\nMeasures request latency and raises alerts.\n' > README.md
quiet 'git add -A && git commit --amend -m "Document the probe and its alerts"'
quiet 'git push -u origin main'
quiet 'git push origin v1.0.0'
gate_note main "$(git rev-parse main)"
cd "$LAB_DIR" || exit 1

# Ravi's spike lives on his machine only. Asha fetches it straight from there into a local
# branch and never checks it out. Then Ravi's machine is gone.
gate_clone ravi
cd ravi || exit 1
as ravi
quiet 'git switch -c spike/histogram'
printf 'BUCKETS_MS = [50, 100, 250, 500, 1000]\n' > probe/histogram.py
_c 'Sketch latency histogram buckets'
printf 'BUCKETS_MS = [50, 100, 250, 500, 1000]\n\ndef bucket(ms):\n    for b in BUCKETS_MS:\n        if ms <= b:\n            return b\n    return float("inf")\n' > probe/histogram.py
_c 'Add bucket lookup'
gate_note spike "$(git rev-parse HEAD)"
cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git fetch ../ravi spike/histogram:spike/histogram'
cd "$LAB_DIR" || exit 1
rm -rf ravi
cd asha || exit 1
quiet 'git fetch origin'
quiet 'git branch -D spike/histogram'
# An edit that was saved, never staged, and discarded.
printf 'P95_ALERT_MS = 350\nP99_ALERT_MS = 900\n' > probe/alerts.py
quiet 'git restore probe/alerts.py'

gate_end
gate_ready
