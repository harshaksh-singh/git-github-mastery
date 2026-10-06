#!/usr/bin/env bash
# Hands-on setup for Lab 7.6: prune and "gone" branches.
# Builds the starting state in a sandbox of its own and tells you where it is.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m07-6
scenario_07_6
require_ref "$LAB_DIR/you/support-bot" refs/remotes/origin/release
require_ref "$LAB_DIR/server/support-bot.git" refs/heads/release/1.0

printf 'Lab 7.6 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m07-6\n'
printf 'First command of the lab:  cd you/support-bot\n'
