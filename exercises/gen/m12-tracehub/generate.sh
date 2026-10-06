#!/usr/bin/env bash
# Exercise 12.12 (Level 5): a clone that was damaged when the machine lost power in the middle of
# a commit. Builds server.git and your clone you/ of the project "tracehub", then damages four
# things inside you/.git. Read SYMPTOMS.md, not this file: the script is the answer.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m12-tracehub

ex_server
ex_clone you
cd you || exit 1
put tracehub/sampler.py <<'F'
"""Decides which traces of the LLM gateway are kept."""

import random


def keep(trace, rate=0.01):
    return random.random() < rate
F
put README.md <<'F'
# tracehub

Collects and samples traces of the LLM gateway.
F
_c 'Add trace sampler'
put tracehub/sampler.py <<'F'
"""Decides which traces of the LLM gateway are kept."""

import random


def keep(trace, rate=0.01):
    if trace.get("error"):
        return True
    return random.random() < rate
F
_c 'Always keep traces with errors'
put tracehub/export.py <<'F'
"""Writes kept traces as JSON lines."""

import json


def export(traces, out):
    for trace in traces:
        out.write(json.dumps(trace, sort_keys=True) + "\n")
F
_c 'Add JSON lines export'
quiet 'git push -u origin main'

quiet 'git switch -c feature/sampling'
put tracehub/rates.py <<'F'
"""Sampling rates per tenant; tenants not listed use DEFAULT."""

DEFAULT = 0.01
RATES = {"internal": 1.0, "enterprise": 0.10}


def rate_for(tenant):
    return RATES.get(tenant, DEFAULT)
F
_c 'Add per-tenant sampling rates'
put tracehub/sampler.py <<'F'
"""Decides which traces of the LLM gateway are kept."""

import random

from tracehub.rates import rate_for


def keep(trace):
    if trace.get("error"):
        return True
    return random.random() < rate_for(trace.get("tenant"))
F
_c 'Sample traces by tenant'

# ---- the damage (what a power loss during the commit can leave behind)
obj() { printf '.git/objects/%s/%s' "$(printf '%s' "$1" | cut -c1-2)" "$(printf '%s' "$1" | cut -c3-)"; }
tip=$(git rev-parse HEAD)
old=$(git rev-parse HEAD~4:tracehub/sampler.py)          # a blob of the first, pushed commit
chmod u+w "$(obj "$tip")" "$(obj "$old")"
: > "$(obj "$tip")"                                       # the new commit object: created, never filled
: > .git/refs/heads/feature/sampling                      # the branch file: created, never filled
head -c 20 .git/index > index.tmp && mv index.tmp .git/index    # the index: cut off
printf 'not a zlib stream\n' > "$(obj "$old")"            # an old object on a bad sector
unset -f obj

ex_end you
