#!/usr/bin/env bash
# Hands-on setup for Lab 13.1: three kinds of tag.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m13-1. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m13-1
scenario_13_1
setup_done 13.1 m13-1 'cd inference-gateway'
