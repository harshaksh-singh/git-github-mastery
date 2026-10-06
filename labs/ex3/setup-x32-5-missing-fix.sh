#!/usr/bin/env bash
# Hands-on setup for Exercise 32.5: which fixes on the release branch never reached main?
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on x32-5
scenario_x32_missing_fix
require_ref "$LAB_DIR/server/chunker.git" refs/heads/release/2.3
require_ref "$LAB_DIR/server/chunker.git" refs/tags/v2.3.1
setup_done 32.5 x32-5/you/chunker 'git log --graph --oneline --decorate main release/2.3'
