#!/usr/bin/env bash
# Hands-on setup for the Git half of Lab 22.2: a server and your clone, nothing tagged yet.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m22-2
scenario_release
require_ref "$LAB_DIR/you/ticket-router" refs/heads/main

printf 'Lab 22.2 (Git half) is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m22-2\n'
printf 'First command of the lab:  cd you/ticket-router\n'
