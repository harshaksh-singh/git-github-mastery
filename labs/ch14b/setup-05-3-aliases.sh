#!/usr/bin/env bash
# Hands-on setup for Lab 5.3: aliases.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m05-3. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m05-3
scenario_05_3
setup_done 5.3 m05-3 'export HOME="$PWD/home"'
