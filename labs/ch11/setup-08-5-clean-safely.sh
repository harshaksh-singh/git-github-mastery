#!/usr/bin/env bash
# Hands-on setup for Lab 8.5 (clean safely). Builds the repository "trainer" with untracked
# and ignored files in $GIT_MASTERY_LABS/hands-on/m08-5. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
sandbox_begin hands-on m08-5
fx_08_5
printf 'Lab 8.5 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m08-5     then:  cd trainer\n'
