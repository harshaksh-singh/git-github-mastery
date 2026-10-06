#!/usr/bin/env bash
# Hands-on setup for Lab 19.2, the Git half of the inventory.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m19-2. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
sandbox_begin hands-on m19-2
scenario_19_2
setup_done 19.2 m19-2 'cd you/practice-repo'
