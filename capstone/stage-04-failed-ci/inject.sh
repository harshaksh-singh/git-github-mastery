#!/usr/bin/env bash
# Stage 4: a pull request whose CI run fails. Applies the incident on top of the state that the
# solution of stage 3 leaves, and writes the evidence files into the sandbox.
# Read BRIEFING.md, not this file, before you start: the script is part of the answer.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/capstone-lib.bash"
cap_inject_begin 4 "$@"

# Thursday 17 September. The embedding client is merged, if its pull request can be merged.
cap_as nandini
quiet '"$LAB_DIR/pr" merge feature/embedding-client --squash'

# Tanvi starts a batch entry point from the main of this morning.
cap_go tanvi
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet 'git switch -c feature/batch-endpoint'
cat > router/batch.py <<'F'
"""Classify a batch of messages in one call."""

from router.classify import FALLBACK, classify


def classify_batch(batch, tenant=None):
    """batch: one candidate list per message. Returns the intents and how many fell back."""
    intents = [classify(candidates, tenant) for candidates in batch]
    return intents, sum(1 for intent in intents if intent == FALLBACK)
F
cat > tests/test_batch.py <<'F'
import unittest

from router.batch import classify_batch


class BatchTest(unittest.TestCase):
    def test_batch_counts_fallbacks(self):
        batch = [[("billing_refund", 0.8, 0.9)], [("order_status", 0.1, 0.2)]]
        self.assertEqual(classify_batch(batch), (["billing_refund", "human_agent"], 1))
F
_cp 'Add batch classification' router/batch.py tests/test_batch.py
quiet 'git push -u origin feature/batch-endpoint'
cap_pr 'open feature/batch-endpoint'
batch_pr=$("$LAB_DIR/pr" list | sed -n 's/^#\([0-9]*\) .*feature\/batch-endpoint.*/\1/p')

# Meanwhile the tech lead changes how the fallback intent is chosen. Her pull request is
# reviewed and merged first. It does not touch any file of Tanvi's branch.
cap_go nandini
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet 'git switch -c feature/tenant-fallback'
cat > router/classify.py <<'F'
"""Pick the intent a message is routed to."""

from router.scoring import blend

THRESHOLD = 0.55
DEFAULT_FALLBACK = "human_agent"
TENANT_FALLBACK = {"acme-retail": "store_support"}


def fallback_for(tenant=None):
    """The intent a message gets when no candidate is good enough."""
    return TENANT_FALLBACK.get(tenant, DEFAULT_FALLBACK)


def classify(candidates, tenant=None):
    """candidates: (intent, keyword_score, embed_score) tuples. Returns the intent to route to."""
    best, best_score = fallback_for(tenant), THRESHOLD
    for intent, kw, emb in candidates:
        score = blend(kw, emb, tenant)
        if score > best_score:
            best, best_score = intent, score
    return best
F
cat > tests/test_classify.py <<'F'
import unittest

from router.classify import classify, fallback_for


class ClassifyTest(unittest.TestCase):
    def test_best_intent_wins(self):
        candidates = [("billing_refund", 0.8, 0.9), ("order_status", 0.2, 0.3)]
        self.assertEqual(classify(candidates), "billing_refund")

    def test_weak_evidence_goes_to_a_human(self):
        self.assertEqual(classify([("billing_refund", 0.2, 0.1)]), "human_agent")

    def test_a_tenant_can_have_its_own_fallback(self):
        self.assertEqual(fallback_for("acme-retail"), "store_support")
        self.assertEqual(classify([("billing_refund", 0.2, 0.1)], "acme-retail"), "store_support")
F
sed -i.bak -e 's/assertEqual(classify(\[("order_status", 0.4, 0.6)\], "acme-retail"), "human_agent")/assertEqual(classify([("order_status", 0.4, 0.6)], "acme-retail"), "store_support")/' tests/test_tenant.py && rm tests/test_tenant.py.bak
_cp 'Make the fallback intent configurable per tenant' router/classify.py tests/test_classify.py tests/test_tenant.py
quiet 'git push -u origin feature/tenant-fallback'
cap_pr 'open feature/tenant-fallback'
cap_as kabir
cap_pr 'merge feature/tenant-fallback --squash'
cap_go nandini
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet 'git branch -D feature/tenant-fallback'
quiet 'git fetch --prune'

# The evidence of the failed run. It is constructed: the commit IDs are the real ones of this
# sandbox, and the test output is what the project's test script prints on the commit that the
# run checked out. Nothing in it was captured from GitHub.
E="$LAB_DIR/evidence/stage-04"
mkdir -p "$E"
head=$(git -C "$LAB_DIR/server.git" rev-parse "refs/pull/$batch_pr/head")
merge=$(git -C "$LAB_DIR/server.git" rev-parse "refs/pull/$batch_pr/merge")
base=$(git -C "$LAB_DIR/server.git" rev-parse "$merge^1")
git -C "$LAB_DIR/server.git" show "$merge:.github/workflows/ci.yml" > "$E/ci.yml"
rm -rf "$E/.tree"; mkdir -p "$E/.tree"
git -C "$LAB_DIR/server.git" archive "$merge" | tar -x -C "$E/.tree"
out=$(bash "$E/.tree/scripts/test.sh" 2>&1 | sed 's/^/    /')
rm -rf "$E/.tree"
cat > "$E/RUN-REPORT.md" <<F
# Run report: CI, pull request #$batch_pr

> Constructed for this exercise. It describes a run of \`.github/workflows/ci.yml\` (a copy is
> next to this file) the way the GitHub web interface and \`gh run view\` would present it.
> Nothing here was captured from GitHub. The commit IDs are the real ones of your sandbox.

| Field | Value |
|---|---|
| Workflow | CI (\`.github/workflows/ci.yml\`) |
| Event | \`pull_request\` |
| Pull request | #$batch_pr, \`feature/batch-endpoint\` into \`main\` |
| Head commit of the pull request | \`$head\` |
| Attempts | 3 (the author re-ran the failed job twice); all three failed in the same step |
| Job | \`test\` on \`ubuntu-24.04\` |
| Conclusion | failure |

## Steps of the job

| Step | Result |
|---|---|
| Set up job | success |
| Check out the repository | success |
| Set up Python | success |
| Show what was checked out | success |
| Run the tests | **failure**, exit code 1 |

## Log excerpts

The lines are paraphrased. The two Git commands have the shape that Chapter 20A, section 20A.8
reproduces with plain Git.

Check out the repository:

    git fetch --no-tags --depth=1 origin +refs/pull/$batch_pr/merge:refs/remotes/pull/$batch_pr/merge
    git checkout --detach refs/remotes/pull/$batch_pr/merge
    HEAD is now at $(printf '%s' "$merge" | cut -c1-7) Merge $head into $base

Set up Python:

    Python 3.13 installed and put on the PATH

Show what was checked out:

    $merge Merge $head into $base

Run the tests:

$out
    Process completed with exit code 1.

## Other facts about the run

- The last run of CI on \`main\` (event \`push\`) is green.
- The workflow file was last changed in pull request #9.
- No secret is used by this workflow. The token of the job is read-only.
F

cap_inject_end 4
