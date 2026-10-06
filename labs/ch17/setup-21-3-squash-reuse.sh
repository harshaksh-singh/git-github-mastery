#!/usr/bin/env bash
# Hands-on setup for Lab 21.3: pull request 1 was squash-merged and its branch still exists.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m21-3
scenario_squash_reuse
require_ref "$LAB_DIR/server/ticket-router.git" refs/heads/feature/priority-routing
require_ref "$LAB_DIR/you/ticket-router" refs/heads/feature/priority-routing

printf 'Lab 21.3 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m21-3\n'
printf 'First command of the lab:  cd you/ticket-router\n'
