#!/usr/bin/env bash
# Hands-on setup for Lab 42.2 (git history reword). Builds the starting state in
# $GIT_MASTERY_LABS/hands-on/m42-2. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m42-2
fx_42_2
printf 'Lab 42.2 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m42-2     then:  cd evalkit\n'
