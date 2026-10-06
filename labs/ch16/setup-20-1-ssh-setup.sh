#!/usr/bin/env bash
# Hands-on setup for Lab 20.1, Part A: the local rehearsal of an SSH setup.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m20-1. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
sandbox_begin hands-on m20-1
scenario_20_1
setup_done 20.1 m20-1 'export HOME="$PWD/home"'
