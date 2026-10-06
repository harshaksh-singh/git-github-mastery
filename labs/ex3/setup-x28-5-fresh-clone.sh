#!/usr/bin/env bash
# Hands-on setup for Exercise 28.5: passes in your clone, fails in a fresh clone.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on x28-5
scenario_x28_fresh_clone
require_ref "$LAB_DIR/server/chunker.git" refs/heads/main
setup_done 28.5 x28-5/you/chunker './scripts/smoke.sh'
