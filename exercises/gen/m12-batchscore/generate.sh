#!/usr/bin/env bash
# Exercise 12.9 (Level 4): a branch that "looks like main" after nobody reset, rebased or deleted
# anything. Builds server.git and the clones you/ and ravi/ of the project "batchscore"; the
# damage is in ravi/. Read SYMPTOMS.md, not this file: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m12-batchscore

ex_server
ex_clone you
cd you || exit 1
put batchscore/worker.py <<'F'
"""Scores one batch of model outputs."""


def score_batch(batch, scorer):
    return [scorer(item) for item in batch]
F
put batchscore/main.py <<'F'
"""Entry point of the batch scoring job."""

import logging

log = logging.getLogger("batchscore")


def main(batches, scorer):
    log.info("scoring %d batches", len(batches))
F
_c 'Add batch scoring worker'
printf '# batchscore\n\nNightly scoring of model outputs, one batch at a time.\n' > README.md
_c 'Add README'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1

ex_clone ravi
cd ravi || exit 1
as ravi
quiet 'git switch -c feature/retry-budget'
put batchscore/budget.py <<'F'
"""A budget of retries shared by all batches of one run."""


class RetryBudget:
    def __init__(self, total):
        self.left = total
F
_c 'Add retry budget'
put batchscore/budget.py <<'F'
"""A budget of retries shared by all batches of one run."""


class RetryBudget:
    def __init__(self, total):
        self.left = total

    def spend(self, batch_id):
        self.left -= 1
        return self.left
F
_c 'Spend the budget per batch'
put batchscore/worker.py <<'F'
"""Scores one batch of model outputs."""


def score_batch(batch, scorer, budget=None):
    if budget is not None and budget.left < 0:
        raise RuntimeError("retry budget spent")
    return [scorer(item) for item in batch]
F
_c 'Refuse to retry when the budget is spent'
sed -e 's/budget.left < 0/budget.left <= 0/' batchscore/worker.py > w.tmp && mv w.tmp batchscore/worker.py
quiet 'git commit -a --amend --no-edit'

# main moves on the server
cd "$LAB_DIR/you" || exit 1
as you
printf '\nRun it with `python3 -m batchscore.main`.\n' >> README.md
_c 'Say how to run the job'
quiet 'git push'

# Ravi updates main, then means to go back to his branch.
cd "$LAB_DIR/ravi" || exit 1
as ravi
quiet 'git switch main'
quiet 'git pull'
quiet 'git switch -C feature/retry-budget'
put batchscore/main.py <<'F'
"""Entry point of the batch scoring job."""

import logging

log = logging.getLogger("batchscore")


def main(batches, scorer, retry_budget=20):
    log.info("scoring %d batches, retry budget %d", len(batches), retry_budget)
F
_c 'Log the retry budget at startup'

ex_end ravi
