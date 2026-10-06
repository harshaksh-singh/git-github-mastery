#!/usr/bin/env bash
# Hands-on setup for Lab 8.6 (stash and a pop conflict). Builds "gateway" and
# "gateway-incident" in $GIT_MASTERY_LABS/hands-on/m08-6. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
sandbox_begin hands-on m08-6
fx_08_6
printf 'Lab 8.6 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m08-6     then:  cd gateway\n'
