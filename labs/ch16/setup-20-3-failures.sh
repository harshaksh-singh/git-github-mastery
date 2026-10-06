#!/usr/bin/env bash
# Hands-on setup for Lab 20.3, Part A: the local rehearsal of three authentication failures.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m20-3. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
sandbox_begin hands-on m20-3
scenario_20_3
setup_done 20.3 m20-3 'export HOME="$PWD/home"'
