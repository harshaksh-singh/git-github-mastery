#!/usr/bin/env bash
# Hands-on setup for Lab 20.4, Part A: the local rehearsal of two identities.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m20-4. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
sandbox_begin hands-on m20-4
scenario_20_4
setup_done 20.4 m20-4 'export HOME="$PWD/home"'
