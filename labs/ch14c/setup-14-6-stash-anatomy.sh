#!/usr/bin/env bash
# Hands-on setup for Lab 14.6 (stash anatomy). Builds "evalkit" in
# $GIT_MASTERY_LABS/hands-on/m14-6. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m14-6
fx_14_6
printf 'Lab 14.6 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m14-6     then:  cd evalkit\n'
