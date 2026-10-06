#!/usr/bin/env bash
# Hands-on setup for Exercise 31.5: assess the exposure of a leaked dummy key.
# Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on x31-5
scenario_x31_exposure
require_ref "$LAB_DIR/server/chunker.git" refs/tags/v0.5.0
require_ref "$LAB_DIR/server/chunker.git" refs/heads/debug/storage
setup_done 31.5 x31-5/you/chunker 'git grep -n DUMMY-KEY'
