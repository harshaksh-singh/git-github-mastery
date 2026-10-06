#!/usr/bin/env bash
# Hands-on setup for Lab 20.2, Part A: the credential helper protocol with a toy helper.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m20-2. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
sandbox_begin hands-on m20-2
scenario_20_2
setup_done 20.2 m20-2 'export HOME="$PWD/home"'
