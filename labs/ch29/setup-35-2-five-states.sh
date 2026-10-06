#!/usr/bin/env bash
# Hands-on setup for Lab 35.2. Builds five repositories, case-1 to case-5, each stopped in the middle of a different operation
# in $GIT_MASTERY_LABS/hands-on/m35-2. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m35-2
fx_35_2
printf 'Lab 35.2 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m35-2     then:  cd case-1\n'
