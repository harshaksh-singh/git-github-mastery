#!/usr/bin/env bash
# Replay of the local part of Lab 27.3: what a deployment of main adds to what is running.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch20b lab-27-3-deploy-range
make_warehouse
scenario_deployed

snip 01-range
note 'Staging runs v1.1.0. A push to main is about to deploy the tip of main.'
run 'git log --oneline v1.1.0..main'
run 'git diff --stat v1.1.0 main'
run './scripts/deploy.sh staging'

snip 02-failure
note 'Somebody re-runs an old workflow run. A re-run uses the commit of the original run:'
run 'git switch --quiet --detach v1.1.0'
run './scripts/deploy.sh staging'
note 'Is that commit behind what staging already had? (exit status 0 means yes)'
run_rc 'git merge-base --is-ancestor HEAD main'
run 'git log --oneline HEAD..main'

snip 03-recovery
run 'git switch --quiet main'
run './scripts/deploy.sh staging'
run_rc 'git merge-base --is-ancestor v1.1.0 HEAD'
lab_end
