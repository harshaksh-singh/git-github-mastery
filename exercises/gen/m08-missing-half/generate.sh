#!/usr/bin/env bash
# Exercise 8.10 (Level 5): a feature that was merged twice and is half missing.
# Builds server.git and the clones you/, asha/ and ravi/ of the project "evalflow".
# Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m08-missing-half
ex_begin m08-missing-half

ex_server
ex_clone asha
cd asha || exit 1
as asha
mkdir -p runner docs
printf 'def run(cases):\n    return [c.execute() for c in cases]\n' > runner/run.py
printf 'timeout_s: 30\n' > settings.yaml
_c 'Add evaluation runner'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1
ex_clone ravi

# Asha's feature, first round.
cd asha || exit 1
quiet 'git switch -c feature/batch-eval'
printf 'def batches(cases, size):\n    return [cases[i:i + size] for i in range(0, len(cases), size)]\n' > runner/batch.py
_c 'Add batch splitter'
printf 'from concurrent.futures import ThreadPoolExecutor\n\ndef run_parallel(groups, run):\n    with ThreadPoolExecutor() as pool:\n        return list(pool.map(run, groups))\n' > runner/parallel.py
_c 'Run batches in parallel'
quiet 'git push -u origin feature/batch-eval'

# Ravi merges it (the button), main moves on, the nightly run turns flaky, Ravi backs it out.
cd "$LAB_DIR/ravi" || exit 1
as ravi
quiet 'git fetch'
quiet 'git merge --no-ff -m "Merge pull request #41 from feature/batch-eval" origin/feature/batch-eval'
printf 'timeout_s: 45\n' > settings.yaml
_c 'Raise the default timeout to 45 seconds'
m1=$(git rev-parse HEAD~1)
quiet "git revert -m 1 --no-edit $m1"
quiet 'git commit --amend -m "Fix nightly: back out flaky batching"'
quiet 'git push'

# Asha fixes the cause on her branch, in new files, and the branch is merged again.
cd "$LAB_DIR/asha" || exit 1
as asha
printf 'MAX_WORKERS = 4\n' > runner/limits.py
_c 'Limit parallelism to four workers'
printf '# Batch evaluation\n\nSplit the cases with runner.batch, run the groups with runner.parallel.\nrunner.limits.MAX_WORKERS caps the number of threads.\n' > docs/batch-eval.md
_c 'Document batch evaluation'
quiet 'git push'
ex_note feature_tip "$(git rev-parse HEAD)"
cd "$LAB_DIR/ravi" || exit 1
as ravi
quiet 'git fetch'
quiet 'git merge --no-ff -m "Merge pull request #47 from feature/batch-eval" origin/feature/batch-eval'
quiet 'git push'
ex_note server_main "$(git rev-parse HEAD)"

cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git switch main && git pull'
cd "$LAB_DIR" || exit 1
as you
ex_clone you

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
