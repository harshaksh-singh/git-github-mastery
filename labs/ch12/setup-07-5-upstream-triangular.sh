#!/usr/bin/env bash
# Hands-on setup for Lab 7.5: upstream configuration and a triangular fork simulation.
# Builds the starting state in a sandbox of its own and tells you where it is.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m07-5
scenario_07_5
require_ref "$LAB_DIR/server/support-bot.git" refs/heads/main
require_ref "$LAB_DIR/ravi/support-bot" refs/heads/main

printf 'Lab 7.5 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m07-5\n'
printf 'First command of the lab:  git clone --bare server/support-bot.git forks/you/support-bot.git\n'
