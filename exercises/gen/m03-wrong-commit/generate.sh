#!/usr/bin/env bash
# Exercise 3.9 (Level 4): a commit made on the meeting-room laptop.
# Builds the repository scorer-service/. Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m03-wrong-commit
ex_begin m03-wrong-commit

quiet 'git init scorer-service'
cd scorer-service || exit 1
quiet 'git config set user.name "Ravi Menon" && git config set user.email ravi@example.com'
as ravi
mkdir -p scorer configs
printf 'def score(batch):\n    return [len(x.strip()) for x in batch]\n' > scorer/score.py
printf 'batch_size: 64\n' > configs/scorer.yaml
_c 'Add batch scorer'
printf 'def with_retry(call, attempts):\n    for _ in range(attempts):\n        try:\n            return call()\n        except TimeoutError:\n            continue\n    raise TimeoutError("all attempts timed out")\n' > scorer/retry.py
_c 'Add retry helper'
ex_note parent "$(git rev-parse HEAD)"

# The pairing session on the meeting-room laptop: its environment carries another identity, a
# debug log is lying in the working tree, and "git add -A" takes everything.
export GIT_AUTHOR_NAME="Meeting Room 4" GIT_AUTHOR_EMAIL="room4@office.example"
export GIT_COMMITTER_NAME="Meeting Room 4" GIT_COMMITTER_EMAIL="room4@office.example"
printf 'def with_retry(call, attempts, budget):\n    for _ in range(min(attempts, budget.remaining)):\n        budget.remaining -= 1\n        try:\n            return call()\n        except TimeoutError:\n            continue\n    raise TimeoutError("all attempts timed out")\n' > scorer/retry.py
printf 'batch_size: 64\nretry_budget: 3\n' > configs/scorer.yaml
printf 'DEBUG batch 17 timed out\nDEBUG batch 17 timed out\nDEBUG batch 17 ok\n' > debug.log
tick
quiet 'git add -A'
git commit -q -m 'Add retry buget to the scoerr' -m 'A batch is retried until the budget of the run is used up, so one slow model cannot hold the whole evaluation.' -m 'Reviewed-by: Asha Rao <asha@example.com>'
ex_note author_date "$(git log -1 --format=%at)"
ex_note retry_blob "$(git rev-parse HEAD:scorer/retry.py)"
ex_note config_blob "$(git rev-parse HEAD:configs/scorer.yaml)"

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
