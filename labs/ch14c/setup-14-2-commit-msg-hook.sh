#!/usr/bin/env bash
# Hands-on setup for Lab 14.2 (a commit-msg hook). Builds "evalkit" and the directory "hooks" in
# $GIT_MASTERY_LABS/hands-on/m14-2. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m14-2
fx_14_2
printf 'Lab 14.2 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m14-2     then:  cd evalkit\n'
