#!/usr/bin/env bash
# Hands-on setup for Lab 32.1: two identical copies of the promptgate repository, one for each
# branching strategy. Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m32-1
fx_lab_32_1
require_ref "$LAB_DIR/github-flow/promptgate" refs/heads/feature/batch-api
require_ref "$LAB_DIR/release-branch/promptgate" refs/heads/feature/batch-api

printf 'Lab 32.1 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m32-1\n'
printf 'First command of the lab:  cd github-flow/promptgate\n'
