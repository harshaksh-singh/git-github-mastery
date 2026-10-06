#!/usr/bin/env bash
# Hands-on setup for Lab 8.4 (restore variants). Builds "evalsuite", its copies and "scorer"
# in $GIT_MASTERY_LABS/hands-on/m08-4. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
sandbox_begin hands-on m08-4
fx_08_4
printf 'Lab 8.4 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m08-4     then:  cd evalsuite\n'
