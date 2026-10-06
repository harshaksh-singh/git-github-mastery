#!/usr/bin/env bash
# Exercise 28.5 (Module 28), model solution: the CI command passes in your clone and fails in
# a fresh clone, for two reasons. The hands-on twin is setup-x28-5-fresh-clone.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x28-fresh-clone
scenario_x28_fresh_clone

snip 01-symptom
run_rc './scripts/smoke.sh'
run 'git status -sb'
note 'What a runner has: a fresh clone and nothing else.'
run 'git clone -q ../../server/chunker.git ../../runner'
run_rc '(cd ../../runner && sh -c ./scripts/smoke.sh)'

snip 02-cause-1
run 'git ls-files -s scripts/smoke.sh'
run 'git config get --show-origin core.fileMode'
run 'git update-index --chmod=+x scripts/smoke.sh'
run 'git ls-files -s scripts/smoke.sh'
run 'git commit -q -m "Make the smoke test executable" && git push -q origin main'
run_rc '(cd ../../runner && git pull -q && sh -c ./scripts/smoke.sh)'

snip 03-cause-2
run 'git ls-files tests'
run 'git check-ignore -v tests/fixtures/sample.txt'
run "printf 'build/\n/build/fixtures/\n__pycache__/\n' > .gitignore"
run 'git status -s'
run 'git add .gitignore tests/fixtures/sample.txt'
run 'git commit -q -m "Track the smoke-test fixture; anchor the ignore rule" && git push -q origin main'

snip 04-verify
run 'rm -rf ../../runner && git clone -q ../../server/chunker.git ../../runner'
run_rc '(cd ../../runner && sh -c ./scripts/smoke.sh)'

lab_end
