#!/usr/bin/env bash
# Hands-on setup for Lab 12.7 (lost work in detached HEAD). Builds "modelserver" in
# $GIT_MASTERY_LABS/hands-on/m12-7. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m12-7
fx_12_7
printf 'Lab 12.7 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m12-7     then:  cd modelserver\n'
