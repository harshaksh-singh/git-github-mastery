#!/usr/bin/env bash
# Replay of the local steps of Lab 26.1: turn the sample project into a repository, run its
# tests, add workflow 1, and break a test on purpose. The GitHub steps of the lab cannot be
# replayed. Commit IDs are not printed, because they change whenever the sample project does.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch20a lab-26-1-first-workflow
[ -f "$COURSE_ROOT/sample-project/pyproject.toml" ] || { echo "sample-project missing" >&2; exit 1; }
[ -f "$COURSE_ROOT/workflows/01-tests.yml" ] || { echo "workflow 01 missing" >&2; exit 1; }
COURSE="$COURSE_ROOT"

snip 01-create
note 'COURSE is the course folder.'
run 'cp -R "$COURSE/sample-project" inventory-api'
run 'cd inventory-api'
run 'git init --quiet'
run_rc 'PYTHONPATH=src python3 -m unittest discover -s tests 2>/dev/null'
run 'mkdir -p .github/workflows'
run 'cp "$COURSE/workflows/01-tests.yml" .github/workflows/'
run 'git add .'
run 'git commit --quiet -m "Add inventory-api and the tests workflow"'
run 'git ls-files'
run 'git status --short --branch'

snip 02-break
note 'Failure scenario: a wrong expectation, on a branch.'
run 'git switch -c break/wrong-total'
run "sed -i.bak 's/{\"bolt\": 5, \"nut\": 7}), 12)/{\"bolt\": 5, \"nut\": 7}), 13)/' tests/test_stock.py && rm tests/test_stock.py.bak"
run 'git diff --stat'
run_rc 'PYTHONPATH=src python3 -m unittest discover -s tests 2>/dev/null'
run 'PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1'
run 'git commit --quiet -am "Break a test on purpose"'

snip 03-recover
note 'Recovery: a new commit that undoes the bad one. The branch history stays honest.'
run 'git revert --no-edit HEAD > /dev/null'
run_rc 'PYTHONPATH=src python3 -m unittest discover -s tests 2>/dev/null'
run 'git log --format=%s -3'
note 'No output from the next command: the branch content equals main again.'
run 'git diff --stat main'
lab_end
