#!/usr/bin/env bash
# Stage 5: work that was never pushed disappears from a teammate's clone. Applies the incident
# on top of the state that the solution of stage 4 leaves. The damage is in tanvi/.
# Read BRIEFING.md, not this file, before you start: the script is part of the answer.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/capstone-lib.bash"
cap_inject_begin 5 "$@"

# Friday 18 September. Tanvi works on routing metrics. She believes she is on a feature branch.
# She is on main.
cap_go tanvi
quiet 'git switch main'
quiet 'git pull --ff-only'
cat > router/metrics.py <<'F'
"""Counters for routing decisions."""
from collections import Counter

routed = Counter()


def record(intent):
    routed[intent] += 1
F
_cp 'Add routing counters' router/metrics.py
cat > router/metrics.py <<'F'
"""Counters for routing decisions."""
from collections import Counter

routed = Counter()
fallbacks_by_tenant = Counter()


def record(intent, tenant=None, fell_back=False):
    routed[intent] += 1
    if fell_back:
        fallbacks_by_tenant[tenant or "default"] += 1
F
_cp 'Count fallbacks per tenant' router/metrics.py
cat >> router/metrics.py <<'F'


def render():
    """The counters as text, one line per counter, sorted by name."""
    lines = [f'routed{{intent="{name}"}} {count}' for name, count in sorted(routed.items())]
    lines += [f'fallbacks{{tenant="{name}"}} {count}' for name, count in sorted(fallbacks_by_tenant.items())]
    return "\n".join(lines) + "\n"
F
cat > tests/test_metrics.py <<'F'
import unittest

from router import metrics


class MetricsTest(unittest.TestCase):
    def test_render_lists_both_counters(self):
        metrics.routed.clear()
        metrics.fallbacks_by_tenant.clear()
        metrics.record("billing_refund")
        metrics.record("store_support", "acme-retail", fell_back=True)
        self.assertEqual(
            metrics.render(),
            'routed{intent="billing_refund"} 1\nrouted{intent="store_support"} 1\nfallbacks{tenant="acme-retail"} 1\n',
        )
F
_cp 'Render the counters as text' router/metrics.py tests/test_metrics.py

# One file staged and never committed, one edit never staged, one file never added at all.
mkdir -p deploy notes
printf 'groups:\n- name: intent-router\n  rules:\n  - alert: FallbackRateHigh\n    expr: rate(fallbacks[10m]) / rate(routed[10m]) > 0.4\n    for: 15m\n' > deploy/alerts.yaml
quiet 'git add -f deploy/alerts.yaml'
printf '\n## Metrics\n\n`router.metrics.render()` returns the routing counters as text.\n' >> README.md
printf 'metrics, still to do\n- histogram of blended scores\n- ask Kabir which tenants need their own alert\n' > notes/metrics-todo.md

# Meanwhile a small pull request is merged, so main moves on the server.
cap_go kabir
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet 'git switch -c docs/batch'
printf '\n## Batches\n\n`router.batch.classify_batch` classifies a list of messages and counts the fallbacks.\n' >> README.md
_cp 'Document the batch entry point' README.md
quiet 'git push -u origin docs/batch'
cap_pr 'open docs/batch'
cap_as nandini
cap_pr 'merge docs/batch --squash'
cap_go kabir
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet 'git branch -D docs/batch'
quiet 'git fetch --prune'

# Tanvi wants "the new main". These three commands are the accident.
cap_go tanvi
quiet 'git fetch'
quiet 'git reset --hard origin/main'
quiet 'git clean -fd'
# She notices that her commits are gone, and creates the branch she thought she was on.
quiet 'git switch -c feature/routing-metrics'

cap_inject_end 5
