#!/usr/bin/env bash
# Hands-on setup for Lab 8.7 (scenario cards). Builds the six card repositories in
# $GIT_MASTERY_LABS/hands-on/m08-7. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
sandbox_begin hands-on m08-7
fx_08_7
printf 'Lab 8.7 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m08-7     then:  cd card-1\n'
