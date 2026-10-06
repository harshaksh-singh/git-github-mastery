#!/usr/bin/env bash
# Hands-on setup for Labs 29.1 and 29.2: a repository "inventory-api" whose .github/workflows/
# holds workflow 12 and the five teaching workflows. Nothing here talks to GitHub.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m29-1
wf_repo
[ -f "$LAB_DIR/inventory-api/.github/workflows/v5-build-and-deploy.yml" ] || { echo 'fixture: workflows missing' >&2; exit 1; }

printf 'Labs 29.1 and 29.2 are ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m29-1\n'
printf 'First command of the lab:  cd inventory-api/.github/workflows && ls\n'
