#!/usr/bin/env bash
# Hands-on setup for Lab 8.1 (the reset prediction table). Builds the starting state in
# $GIT_MASTERY_LABS/hands-on/m08-1 and tells you how to enter it. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures.bash"
sandbox_begin hands-on m08-1
fx_08_1
printf 'Lab 8.1 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m08-1     then:  cd promptlab\n'
