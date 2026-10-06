#!/usr/bin/env bash
# Hands-on setup for Lab 13.3: describe and versions.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m13-3. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m13-3
scenario_13_3
setup_done 13.3 m13-3 'cd inference-gateway'
