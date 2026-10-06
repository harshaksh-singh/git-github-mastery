#!/usr/bin/env bash
# Hands-on setup for Lab 7.7: refspec surgery.
# Builds the starting state in a sandbox of its own and tells you where it is.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m07-7
scenario_07_7
require_ref "$LAB_DIR/server/support-bot.git" refs/pull/7/head
require_ref "$LAB_DIR/you/support-bot" refs/remotes/origin/main

printf 'Lab 7.7 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m07-7\n'
printf 'First command of the lab:  cd you/support-bot\n'
