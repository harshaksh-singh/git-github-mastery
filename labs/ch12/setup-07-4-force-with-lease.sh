#!/usr/bin/env bash
# Hands-on setup for Lab 7.4: when --force-with-lease saves you and when it does not.
# Builds the starting state in a sandbox of its own and tells you where it is.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m07-4
scenario_07_4
require_ref "$LAB_DIR/you/support-bot" refs/remotes/origin/feature/prompt-cache
require_ref "$LAB_DIR/asha/support-bot" refs/heads/feature/prompt-cache

printf 'Lab 7.4 is ready in %s\n' "$LAB_DIR"
printf 'Open the lab shell there:  labs/shell m07-4\n'
printf 'First command of the lab:  cd you/support-bot\n'
