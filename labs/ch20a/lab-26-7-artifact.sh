#!/usr/bin/env bash
# Replay of the local steps of Lab 26.7: the simulated deployment script of the sample project,
# run against a directory that stands in for the downloaded artifact, and its two failure modes.
# The file names in dist/ are stand-ins: nothing is built here.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch20a lab-26-7-artifact
[ -f "$COURSE_ROOT/sample-project/scripts/deploy.sh" ] || { echo "sample-project missing" >&2; exit 1; }
unset GITHUB_SHA GITHUB_REF
quiet 'mkdir -p scripts && cp "$COURSE_ROOT/sample-project/scripts/deploy.sh" scripts/'

snip 01-deploy
run 'mkdir dist'
run 'touch dist/inventory_api-0.1.0.tar.gz dist/inventory_api-0.1.0-py3-none-any.whl'
run_rc 'bash scripts/deploy.sh staging dist'

snip 02-failures
note 'The artifact did not arrive: the directory is empty.'
run 'mkdir empty'
run_rc 'bash scripts/deploy.sh staging empty'
note 'A misspelled environment name:'
run_rc 'bash scripts/deploy.sh stagging dist'
lab_end
