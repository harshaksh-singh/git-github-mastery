#!/usr/bin/env bash
# Hands-on setup for the local rehearsal of Lab 21.1: upstream, your fork, your clone, and the
# maintainer's clone. Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m21-1
scenario_fork
require_ref "$LAB_DIR/server/ticket-router.git" refs/heads/main
require_ref "$LAB_DIR/forks/you/ticket-router.git" refs/heads/main
require_ref "$LAB_DIR/you/ticket-router" refs/heads/main

printf 'Lab 21.1 (local rehearsal) is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m21-1\n'
printf 'First command of the lab:  cd you/ticket-router\n'
