#!/usr/bin/env bash
# Hands-on setup for Lab 12.11 (a force push seen from the local side). Builds "server.git",
# the clones "askdocs", "asha" and "ravi", and the directory "incident" in
# $GIT_MASTERY_LABS/hands-on/m12-11. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m12-11
fx_12_11
printf 'Lab 12.11 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m12-11     then:  cd askdocs\n'
