#!/usr/bin/env bash
# Final test, practical lab "debugging" (section 16): the project "latencylab".
# Builds one repository in which a check that passed at v1.0 fails on main. Read TASK.md, not
# this file, before you start: the script names the commit you are asked to find.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/final-lib/final-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin final debugging
final_begin debugging

quiet 'git init latencylab'
cd latencylab || exit 1
mkdir -p config
printf 'timeout_ms: 400\nretries: 2\nbackoff_ms: 100\n' > config/client.yaml
cat > check-p95.sh <<'CHECK'
#!/bin/sh
# Passes when the worst case of one request (every attempt times out, with a pause before each
# retry) still fits into the p95 target of 2000 ms. Run it from the top of the repository.
t=$(sed -n 's/^timeout_ms: //p' config/client.yaml)
r=$(sed -n 's/^retries: //p' config/client.yaml)
b=$(sed -n 's/^backoff_ms: //p' config/client.yaml)
total=$(( t * (r + 1) + b * r ))
echo "worst case: ${total} ms"
[ "$total" -le 2000 ]
CHECK
_c 'Add the client configuration and the p95 check'
final_note check "$(git rev-parse HEAD:check-p95.sh)"
printf 'def call(client, request):\n    return client.send(request)\n' > client.py
_c 'Add the client wrapper'
quiet 'git tag -a v1.0 -m "Release 1.0"'
printf 'def histogram(samples, buckets):\n    return [sum(1 for s in samples if s <= b) for b in buckets]\n' > histogram.py
_c 'Add a latency histogram'

quiet 'git switch -c feature/second-region'
printf 'primary: eu-central\nsecondary: ap-south\n' > config/regions.yaml
_c 'Add the second region'
printf 'timeout_ms: 400\nretries: 2\nbackoff_ms: 500\n' > config/client.yaml
printf 'primary: eu-central\nsecondary: ap-south\nfailover_after_errors: 3\n' > config/regions.yaml
_c 'Tune client defaults for the new region'
final_note bad "$(git rev-parse HEAD)"
printf 'def pick(regions, errors):\n    return regions["secondary"] if errors >= 3 else regions["primary"]\n' > failover.py
_c 'Add region failover'

quiet 'git switch main'
printf 'def p95(samples):\n    ordered = sorted(samples)\n    return ordered[int(0.95 * (len(ordered) - 1))]\n' > percentile.py
_c 'Add the p95 calculation'
quiet 'git merge --no-ff -m "Merge feature/second-region" feature/second-region'
quiet 'git branch -d feature/second-region'
printf '# latencylab\n\nMeasures and bounds request latency.\n' > README.md
_c 'Add README'
printf 'timeout_ms: 450\nretries: 2\nbackoff_ms: 500\n' > config/client.yaml
_c 'Raise the timeout to 450 ms'
printf 'def call(client, request, trace=None):\n    return client.send(request, trace=trace)\n' > client.py
_c 'Pass a trace context to the client'
final_note main "$(git rev-parse HEAD)"

final_end
final_ready
