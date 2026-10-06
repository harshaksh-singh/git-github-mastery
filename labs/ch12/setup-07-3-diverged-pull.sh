#!/usr/bin/env bash
# Hands-on setup for Lab 7.3: the diverged pull error and the three configurations.
# Builds the starting state in a sandbox of its own and tells you where it is.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m07-3
scenario_07_3
require_ref "$LAB_DIR/you/support-bot" refs/heads/main
require_ref "$LAB_DIR/asha/support-bot" refs/heads/main

printf 'Lab 7.3 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m07-3\n'
printf 'First command of the lab:  cd you/support-bot\n'
