#!/usr/bin/env bash
# Hands-on setup for Lab 24.1: SSH signing locally.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m24-1. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m24-1
scenario_24_1
setup_done 24.1 m24-1 'export HOME="$PWD/home"'
