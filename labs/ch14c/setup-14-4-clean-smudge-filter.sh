#!/usr/bin/env bash
# Hands-on setup for Lab 14.4 (a clean and smudge filter). Builds "server.git" and "modelhub" in
# $GIT_MASTERY_LABS/hands-on/m14-4. Run it again to start over.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
sandbox_begin hands-on m14-4
fx_14_4
printf 'Lab 14.4 is ready in %s\n' "$LAB_DIR"
printf 'Enter it with:  labs/shell m14-4     then:  cd modelhub\n'
