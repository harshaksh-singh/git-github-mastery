#!/usr/bin/env bash
# Hands-on setup for Lab 13.2: a moved tag between two clones.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m13-2. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m13-2
scenario_13_2
setup_done 13.2 m13-2 'cd you/inference-gateway'
