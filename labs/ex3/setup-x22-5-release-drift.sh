#!/usr/bin/env bash
# Hands-on setup for Exercise 22.5: a release tag that the platform created.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on x22-5
scenario_x22_release
require_ref "$LAB_DIR/server/chunker.git" refs/tags/v0.9.0
require_ref "$LAB_DIR/server/chunker.git" refs/tags/v0.8.0
setup_done 22.5 x22-5/you/chunker 'git fetch'
