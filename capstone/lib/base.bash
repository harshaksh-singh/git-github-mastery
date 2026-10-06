# capstone/lib/base.bash — builds the company repository "intent-router" of Tessaly.
# Sourced by capstone-lib.bash (cap_build_to). Never run directly.
#
# The history it creates, Monday 7 to Friday 11 September 2026:
#   two direct commits by the tech lead, then pull requests #1 to #11 (squash merges and two
#   merge commits), the annotated tags v1.0.0, v1.1.0, v1.2.0 and v1.3.0, and two open pull
#   requests (#12 and #13) on feature branches.

# ---- file contents ---------------------------------------------------------------------------
_f_readme() {
cat > README.md <<'F'
# intent-router

Classifies an incoming customer message into an intent and routes it to a queue.

Every candidate intent gets two scores between 0 and 1: a keyword score (how many of the
intent's keywords occur in the message) and an embedding score (similarity to the intent's
examples, computed by the embedding service). `router.scoring.blend` combines them, and
`router.classify.classify` picks the best intent above a threshold.

Run the tests with `bash scripts/test.sh`.
F
}

_f_gitignore() { printf '__pycache__/\n*.pyc\n.venv/\n' > .gitignore; }

_f_keywords() {   # _f_keywords <original|simplified> <plain|lower>
  local doc cap body split
  if [ "$1" = original ]; then
    doc='"""Keyword evidence for an intent: how many of its keywords occur in the message."""'
    cap='KEYWORD_CAP = 5'
    body='    """Map a hit count to a score in [0, 1]. Five or more hits count as full evidence."""
    return min(hits, KEYWORD_CAP) / KEYWORD_CAP'
  else
    doc='"""Keyword evidence for an intent."""'
    cap='CAP = 5'
    body='    """Map a hit count to a score: hits per cap."""
    return hits / CAP'
  fi
  if [ "$2" = lower ]; then split='    words = text.lower().split()'; else split='    words = text.split()'; fi
  cat > router/keywords.py <<F
$doc

$cap


def count_hits(text, keywords):
    """How many times the keywords of an intent occur in the text."""
$split
    return sum(1 for word in words if word in keywords)


def keyword_score(hits):
$body
F
}

_f_scoring() {   # _f_scoring <weight>
  cat > router/scoring.py <<F
"""Blend the keyword score and the embedding score of one candidate intent."""

EMBED_WEIGHT = $1


def blend(keyword_score, embed_score):
    """Both inputs are in [0, 1]; so is the result."""
    return (1 - EMBED_WEIGHT) * keyword_score + EMBED_WEIGHT * embed_score
F
}

_f_classify() {   # _f_classify <none|fallback>
  if [ "$1" = none ]; then
    cat > router/classify.py <<'F'
"""Pick the intent a message is routed to."""

from router.scoring import blend

THRESHOLD = 0.55


def classify(candidates):
    """candidates: (intent, keyword_score, embed_score) tuples. Returns the best intent or None."""
    best, best_score = None, THRESHOLD
    for intent, kw, emb in candidates:
        score = blend(kw, emb)
        if score > best_score:
            best, best_score = intent, score
    return best
F
  else
    cat > router/classify.py <<'F'
"""Pick the intent a message is routed to."""

from router.scoring import blend

THRESHOLD = 0.55
FALLBACK = "human_agent"


def classify(candidates):
    """candidates: (intent, keyword_score, embed_score) tuples. Returns the intent to route to."""
    best, best_score = FALLBACK, THRESHOLD
    for intent, kw, emb in candidates:
        score = blend(kw, emb)
        if score > best_score:
            best, best_score = intent, score
    return best
F
  fi
}

_f_test_sh() {
cat > scripts/test.sh <<'F'
#!/usr/bin/env bash
# Run the unit tests. Prints one line per failing test and a last line: OK or FAILED (...).
cd "$(dirname "$0")/.." || exit 2
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests 2>&1 \
  | grep -E '^(ERROR|FAIL|OK|FAILED)' | sed -E 's/ \(.*\)$//; s/^(FAILED).*/\1/'
exit "${PIPESTATUS[0]}"
F
chmod +x scripts/test.sh
}

_f_test_scoring() {
cat > tests/test_scoring.py <<'F'
import unittest

from router.keywords import count_hits, keyword_score
from router.scoring import EMBED_WEIGHT, blend


class ScoringTest(unittest.TestCase):
    def test_count_hits(self):
        self.assertEqual(count_hits("refund my order", {"refund", "money"}), 1)

    def test_keyword_score_grows_with_hits(self):
        self.assertEqual(keyword_score(0), 0.0)
        self.assertEqual(keyword_score(2), 0.4)
        self.assertEqual(keyword_score(5), 1.0)

    def test_blend_of_equal_scores(self):
        self.assertAlmostEqual(blend(0.5, 0.5), 0.5)

    def test_blend_weights_the_embedding(self):
        self.assertAlmostEqual(blend(0.0, 0.4), EMBED_WEIGHT * 0.4)
F
}

_f_test_classify() {
cat > tests/test_classify.py <<'F'
import unittest

from router.classify import FALLBACK, classify


class ClassifyTest(unittest.TestCase):
    def test_best_intent_wins(self):
        candidates = [("billing_refund", 0.8, 0.9), ("order_status", 0.2, 0.3)]
        self.assertEqual(classify(candidates), "billing_refund")

    def test_weak_evidence_goes_to_a_human(self):
        self.assertEqual(classify([("billing_refund", 0.2, 0.1)]), FALLBACK)
F
}

_f_codeowners() {
cat > .github/CODEOWNERS <<'F'
# The last matching pattern wins. Teams are teams of the organization "tessaly".
*                     @tessaly/intent-router
/router/scoring.py    @tessaly/ml
/router/keywords.py   @tessaly/ml
/data/                @tessaly/ml
/.github/             @tessaly/platform
/scripts/             @tessaly/platform
F
}

_f_ci() {   # _f_ci <python version>
  cat > .github/workflows/ci.yml <<F
# Tests for every pull request and for every push to main and to a release branch.
name: CI

on:
  push:
    branches: [main, "release/**"]
  pull_request:

permissions:
  contents: read

concurrency:
  group: \${{ github.workflow }}-\${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    name: test
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    steps:
      - name: Check out the repository
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false

      - name: Set up Python
        uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
        with:
          python-version: "$1"

      - name: Show what was checked out
        run: git log -1 --format='%H %s'

      - name: Run the tests
        run: bash scripts/test.sh
F
}

_f_release() {
cat > .github/workflows/release.yml <<'F'
# Builds the release archive when a version tag is pushed.
name: Release

on:
  push:
    tags: ["v*"]

permissions:
  contents: read

jobs:
  build:
    name: build
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    steps:
      - name: Check out the repository with all history and tags
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          fetch-depth: 0
          persist-credentials: false

      - name: Set up Python
        uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
        with:
          python-version: "3.13"

      - name: Refuse a tag that is not annotated
        run: test "$(git cat-file -t "refs/tags/$GITHUB_REF_NAME")" = tag

      - name: Run the tests
        run: bash scripts/test.sh

      - name: Build the archive
        run: |
          bash scripts/version.sh > VERSION.txt
          tar -czf intent-router.tar.gz router VERSION.txt

      - name: Upload the archive
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: intent-router
          path: intent-router.tar.gz
          if-no-files-found: error
F
}

_f_routes() {   # _f_routes <plain|priorities>
  if [ "$1" = plain ]; then
    printf 'billing_refund: billing\norder_status: orders\naccount_access: accounts\nhuman_agent: triage\n' > router/routes.yaml
  else
    printf 'billing_refund: {queue: billing, priority: 2}\norder_status: {queue: orders, priority: 3}\naccount_access: {queue: accounts, priority: 1}\nhuman_agent: {queue: triage, priority: 2}\n' > router/routes.yaml
  fi
}

# ---- history ---------------------------------------------------------------------------------
# _land <person> <branch> <--squash|--merge>: push the current branch, open a pull request, and
# have the tech lead merge it; then bring the author's main up to date and delete the local branch.
_land() {
  quiet "git push -u origin $2"
  cap_pr "open $2"
  cap_as nandini
  cap_pr "merge $2 $3"
  cap_as "$1"
  quiet 'git switch main'
  quiet 'git pull --ff-only'
  quiet "git branch -D $2"
  quiet 'git fetch --prune'
}

cap_build_base() {
  cd "$LAB_DIR" || return 1
  cap_at 0
  cap_as nandini
  quiet 'git init --bare server.git'
  quiet 'git -C server.git config set receive.hideRefs refs/pull'
  cp "$CAP_HOME/lib/pr.sh" "$LAB_DIR/pr" && chmod +x "$LAB_DIR/pr"
  printf '#!/bin/sh\n# Keeps refs/pull/<n>/head and refs/pull/<n>/merge in line after every push.\nexec "$(pwd)/../pr" sync > /dev/null 2>&1\n' > server.git/hooks/post-receive
  chmod +x server.git/hooks/post-receive

  # Monday: the skeleton, pushed directly by the tech lead before the pull-request rule existed.
  cap_clone nandini
  cap_go nandini
  mkdir -p router tests scripts
  _f_readme; _f_gitignore; : > router/__init__.py
  _f_keywords original plain; _f_scoring 0.7; _f_classify none
  _c 'Initial service skeleton'
  _f_test_sh; _f_test_scoring
  _c 'Add unit tests and the test script'
  quiet 'git push -u origin main'
  for p in you kabir tanvi; do cap_clone "$p"; done

  cap_go tanvi
  quiet 'git switch -c chore/ci'
  mkdir -p .github/workflows
  _f_codeowners; _f_ci 3.12
  _c 'Add CODEOWNERS and the CI workflow'
  _land tanvi chore/ci --squash                                   # 1

  cap_go you
  quiet 'git pull --ff-only'
  quiet 'git switch -c feature/routing-table'
  _f_routes plain
  _c 'Add the intent-to-queue routing table'
  _land you feature/routing-table --squash                        # 2

  cap_go nandini
  quiet 'git pull --ff-only'
  quiet "git tag -a v1.0.0 -m 'intent-router 1.0.0'"
  quiet 'git push origin v1.0.0'

  # Tuesday
  cap_at 1
  cap_go kabir
  quiet 'git pull --ff-only'
  quiet 'git switch -c feature/eval-set'
  mkdir -p data
  printf 'outs:\n- md5: 3f2a9c0e5b7d41c88a6e0f4d2b915c7a\n  size: 48211937\n  path: eval-messages.jsonl\n' > data/eval-messages.jsonl.dvc
  printf '/eval-messages.jsonl\n' > data/.gitignore
  _c 'Add the evaluation set pointer'
  cat > scripts/evaluate.py <<'F'
"""Offline evaluation: accuracy of classify() on data/eval-messages.jsonl (fetched with dvc pull)."""
import json
import sys

from router.classify import classify


def main(path):
    total = correct = 0
    with open(path) as handle:
        for line in handle:
            row = json.loads(line)
            total += 1
            correct += classify(row["candidates"]) == row["intent"]
    print(f"accuracy {correct / total:.3f} on {total} messages")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "data/eval-messages.jsonl")
F
  _c 'Add the offline evaluation script'
  _land kabir feature/eval-set --merge                            # 3

  cap_go tanvi
  quiet 'git pull --ff-only'
  quiet 'git switch -c chore/release-workflow'
  _f_release
  printf '#!/usr/bin/env bash\n# The version of this build: the nearest annotated tag, and the distance from it.\ngit describe\n' > scripts/version.sh
  chmod +x scripts/version.sh
  _c 'Add the release workflow'
  _land tanvi chore/release-workflow --squash                     # 4

  cap_go nandini
  quiet 'git pull --ff-only'
  quiet "git tag -a v1.1.0 -m 'intent-router 1.1.0'"
  quiet 'git push origin v1.1.0'

  # Wednesday
  cap_at 2
  cap_go you
  quiet 'git pull --ff-only'
  quiet 'git switch -c feature/human-fallback'
  _f_classify fallback; _f_test_classify
  _c 'Route unknown intents to a human agent'
  _land you feature/human-fallback --squash                       # 5

  cap_go kabir
  quiet 'git pull --ff-only'
  quiet 'git switch -c docs/scoring-formula'
  printf '\n## Scoring\n\n`blend = (1 - EMBED_WEIGHT) * keyword_score + EMBED_WEIGHT * embed_score`, and a message is\nrouted to the best intent whose blended score is above `THRESHOLD`; otherwise to a human agent.\n' >> README.md
  _c 'Document the scoring formula'
  _land kabir docs/scoring-formula --squash                       # 6

  cap_go nandini
  quiet 'git pull --ff-only'
  quiet "git tag -a v1.2.0 -m 'intent-router 1.2.0'"
  quiet 'git push origin v1.2.0'

  # Thursday
  cap_at 3
  cap_go you
  quiet 'git pull --ff-only'
  quiet 'git switch -c feature/queue-priorities'
  _f_routes priorities
  _c 'Give every queue a priority'
  printf '\n## Routing table\n\n`router/routes.yaml` maps an intent to a queue and a priority (1 is the most urgent).\n' >> README.md
  _c 'Document the routing table'
  quiet 'git push -u origin feature/queue-priorities'
  cap_pr "open feature/queue-priorities --title 'Queue priorities'"
  cap_as nandini; cap_pr 'merge feature/queue-priorities --merge'; cap_as you          # 7
  quiet 'git switch main'; quiet 'git pull --ff-only'; quiet 'git branch -D feature/queue-priorities'; quiet 'git fetch --prune'

  cap_go kabir
  quiet 'git pull --ff-only'
  quiet 'git switch -c refactor/keyword-scoring'
  quiet "sed -i.bak -e 's/KEYWORD_CAP/CAP/g' router/keywords.py && rm router/keywords.py.bak"
  _c 'Rename KEYWORD_CAP to CAP'
  quiet "sed -i.bak -e 's|return min(hits, CAP) / CAP|return hits / CAP|' router/keywords.py && rm router/keywords.py.bak"
  _c 'Simplify keyword_score'
  _f_keywords simplified plain
  _c 'Shorten the keyword docstrings'
  quiet 'git push -u origin refactor/keyword-scoring'
  cap_pr "open refactor/keyword-scoring --title 'Simplify keyword scoring'"
  cap_as nandini; cap_pr 'merge refactor/keyword-scoring --squash'; cap_as kabir      # 8
  quiet 'git switch main'; quiet 'git pull --ff-only'; quiet 'git branch -D refactor/keyword-scoring'; quiet 'git fetch --prune'

  cap_go tanvi
  quiet 'git pull --ff-only'
  quiet 'git switch -c chore/ci-python'
  _f_ci 3.13
  _c 'Pin CI to Python 3.13'
  _land tanvi chore/ci-python --squash                            # 9

  # Friday
  cap_at 4
  cap_go you
  quiet 'git pull --ff-only'
  quiet 'git switch -c fix/case-insensitive-hits'
  _f_keywords simplified lower
  _c 'Count keyword hits case-insensitively'
  _land you fix/case-insensitive-hits --squash                    # 10

  cap_go kabir
  quiet 'git pull --ff-only'
  quiet 'git switch -c tune/embed-weight'
  _f_scoring 0.8
  _c 'Raise the embedding weight to 0.8'
  _land kabir tune/embed-weight --squash                          # 11

  cap_go nandini
  quiet 'git pull --ff-only'
  quiet "git tag -a v1.3.0 -m 'intent-router 1.3.0'"
  quiet 'git push origin v1.3.0'

  # Two feature branches with open pull requests, both started on Friday afternoon.
  cap_at 4 300
  cap_go you
  quiet 'git pull --ff-only'
  quiet 'git switch -c feature/low-confidence-penalty'
  cat > router/scoring.py <<'F'
"""Blend the keyword score and the embedding score of one candidate intent."""

EMBED_WEIGHT = 0.8
DISAGREEMENT = 0.6


def blend(keyword_score, embed_score):
    """Both inputs are in [0, 1]; so is the result."""
    score = (1 - EMBED_WEIGHT) * keyword_score + EMBED_WEIGHT * embed_score
    if abs(keyword_score - embed_score) > DISAGREEMENT:
        score *= 0.5  # the two signals disagree: trust neither
    return score
F
  cat >> tests/test_scoring.py <<'F'

    def test_disagreement_halves_the_score(self):
        self.assertAlmostEqual(blend(1.0, 0.0), (1 - EMBED_WEIGHT) / 2)
        self.assertAlmostEqual(blend(0.9, 0.5), (1 - EMBED_WEIGHT) * 0.9 + EMBED_WEIGHT * 0.5)
F
  _c 'Halve the score when keyword and embedding disagree'
  quiet 'git push -u origin feature/low-confidence-penalty'
  cap_pr 'open feature/low-confidence-penalty'                    # 12
  quiet 'git switch main'

  cap_go kabir
  quiet 'git pull --ff-only'
  quiet 'git switch -c feature/tenant-weights'
  cat > router/scoring.py <<'F'
"""Blend the keyword score and the embedding score of one candidate intent."""

EMBED_WEIGHT = 0.8
TENANT_EMBED_WEIGHT = {"acme-retail": 0.6}


def blend(keyword_score, embed_score, tenant=None):
    """Both inputs are in [0, 1]; so is the result."""
    weight = TENANT_EMBED_WEIGHT.get(tenant, EMBED_WEIGHT)
    return (1 - weight) * keyword_score + weight * embed_score
F
  quiet "sed -i.bak -e 's/^def classify(candidates):/def classify(candidates, tenant=None):/' -e 's/blend(kw, emb)/blend(kw, emb, tenant)/' router/classify.py && rm router/classify.py.bak"
  cat > tests/test_tenant.py <<'F'
import unittest

from router.classify import classify
from router.scoring import EMBED_WEIGHT, blend


class TenantTest(unittest.TestCase):
    def test_tenant_weight_overrides_the_default(self):
        self.assertAlmostEqual(blend(0.0, 0.5, "acme-retail"), 0.3)
        self.assertAlmostEqual(blend(0.0, 0.5, "unknown-tenant"), EMBED_WEIGHT * 0.5)

    def test_classify_uses_the_tenant_weight(self):
        self.assertEqual(classify([("order_status", 0.4, 0.6)]), "order_status")
        self.assertEqual(classify([("order_status", 0.4, 0.6)], "acme-retail"), "human_agent")
F
  _c 'Add per-tenant embedding weights'
  quiet 'git push -u origin feature/tenant-weights'
  cap_pr 'open feature/tenant-weights'                            # 13
  quiet 'git switch main'

  for p in nandini tanvi you kabir; do cap_go "$p"; quiet 'git fetch'; done
  cap_as you
  cd "$LAB_DIR" || return 1
  printf '0\n' > "$LAB_DIR/.capstone-stage"
}
