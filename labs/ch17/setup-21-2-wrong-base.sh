#!/usr/bin/env bash
# Hands-on setup for Lab 21.2: a branch created from main whose pull request targets release/1.0.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m21-2
scenario_wrong_base you
require_ref "$LAB_DIR/server/ticket-router.git" refs/heads/release/1.0
require_ref "$LAB_DIR/you/ticket-router" refs/heads/fix/empty-subject

printf 'Lab 21.2 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m21-2\n'
printf 'First command of the lab:  cd you/ticket-router\n'
