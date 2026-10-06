#!/usr/bin/env bash
# Hands-on setup for Lab 5.4: your deliberate configuration.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m05-4. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m05-4
scenario_05_4
setup_done 5.4 m05-4 'export HOME="$PWD/home"'
