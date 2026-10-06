#!/usr/bin/env bash
# Hands-on setup for Lab 14.5 (rerere, resolve once). Builds "ranker" and "ranker-wrong" in
# $GIT_MASTERY_LABS/hands-on/m14-5. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m14-5
fx_14_5
printf 'Lab 14.5 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m14-5     then:  cd ranker\n'
