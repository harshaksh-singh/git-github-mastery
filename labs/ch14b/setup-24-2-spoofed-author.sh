#!/usr/bin/env bash
# Hands-on setup for Lab 24.2: a spoofed-author commit.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m24-2. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m24-2
scenario_24_2
setup_done 24.2 m24-2 'cd you/inference-gateway'
