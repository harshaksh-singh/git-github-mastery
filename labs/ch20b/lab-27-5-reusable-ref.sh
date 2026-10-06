#!/usr/bin/env bash
# Replay of the local part of Lab 27.5: which version of a called workflow file a run uses
# when the caller refers to it with "./".
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch20b lab-27-5-reusable-ref
make_warehouse
scenario_reusable

snip 01-two-versions
run 'git ls-files .github/workflows'
run 'git grep -n "uses:" main -- .github/workflows/deploy.yml'
run 'git diff --stat main ci/python-version'
run 'git grep -c "python-version" main ci/python-version -- .github/workflows/reusable-deploy.yml'

snip 02-failure
note 'On main, the caller starts passing an input that the called file on main does not declare:'
run "printf '      python-version: \"3.13\"\n' >> .github/workflows/deploy.yml"
run 'git commit -q -am "Deploy with Python 3.13"'
run 'git show HEAD:.github/workflows/deploy.yml | tail -n 4'
run_rc 'git grep -c "python-version" HEAD -- .github/workflows/reusable-deploy.yml'

snip 03-recovery
note 'Caller and called file must agree in the same commit. Bring the declaration to main:'
run 'git merge --quiet --no-ff -m "Merge ci/python-version" ci/python-version'
run 'git grep -c "python-version" HEAD -- .github/workflows'
lab_end
