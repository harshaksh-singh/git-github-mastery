#!/usr/bin/env bash
# Hands-on setup for Lab 5.2: two identities with includeIf.
# Builds the starting state in $GIT_MASTERY_LABS/hands-on/m05-2. Running the script again
# throws the sandbox away and builds it afresh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on m05-2
scenario_05_2
setup_done 5.2 m05-2 'export HOME="$PWD/home"'
