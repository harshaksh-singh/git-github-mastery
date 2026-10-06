#!/usr/bin/env bash
# Hands-on setup for Lab 42.3 (a format-patch and am round trip). Builds the starting state in
# $GIT_MASTERY_LABS/hands-on/m42-3. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m42-3
fx_42_3
printf 'Lab 42.3 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m42-3     then:  cd fork\n'
